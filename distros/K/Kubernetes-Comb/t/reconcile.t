use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Carp qw( croak );
use Future;
use Kubernetes::Comb;
use Kubernetes::Comb::Client::Fake;
use Kubernetes::Comb::CRD::CombStatus;
use TestComb::Configurable;
use TestComb::Fixtures qw( comb_cr comb_labels deployment service set_status );

{
  package TestComb::NoClient;
  use Moo;
  extends 'TestComb::Configurable';
  sub _build_k8s { die "no kubeconfig here\n" }
}

{
  package TestComb::BrokenRecord;
  use Moo;
  extends 'TestComb::Configurable';
  sub _status_from { die "cannot build a status\n" }
}

# A Comb without a custom resource: nats in platform, one Deployment.
sub comb {
  my ( %args ) = @_;
  my $k8s = exists $args{k8s} ? delete $args{k8s} : Kubernetes::Comb::Client::Fake->new;
  my $class = delete $args{class} // 'TestComb::Configurable';
  return ( $class->new(
    name      => 'nats',
    namespace => 'platform',
    ( $k8s ? ( k8s => $k8s ) : () ),
    parts     => [ deployment('nats') ],
    %args
  ), $k8s );
}

# A Comb built from a custom resource stored in the fake.
sub cr_comb {
  my ( %args ) = @_;
  my $spec   = delete $args{spec} // {};
  my $status = delete $args{status};
  my $k8s    = delete $args{k8s} // Kubernetes::Comb::Client::Fake->new;
  my $class  = delete $args{class} // 'TestComb::Configurable';
  my $cr = comb_cr( name => 'nats', class => $class, spec => $spec );
  $k8s->add( $status ? { %{ $cr->TO_JSON }, status => $status } : $cr );
  return ( $class->new(
    crd   => $k8s->object( Comb => 'nats', namespace => 'platform' ),
    k8s   => $k8s,
    parts => [ deployment('nats') ],
    %args
  ), $k8s );
}

sub condition {
  my ( $status, $type ) = @_;
  my ( $condition ) = grep { $_->type eq $type } @{ $status->conditions // [] };
  return $condition;
}

sub managed {
  my ( $status ) = @_;
  return [ map { $_->TO_JSON } @{ $status->managedResources // [] } ];
}

sub reconciled {
  my ( $comb ) = @_;
  my $f = $comb->reconcile;
  ok $f->is_done, 'the reconcile Future is done';
  return $f->get;
}

my %deployment_nats = ( apiVersion => 'apps/v1', kind => 'Deployment', namespace => 'platform', name => 'nats' );
my %service_old     = ( apiVersion => 'v1',      kind => 'Service',    namespace => 'platform', name => 'old' );

# The status a previous step recorded, as the CR holds it.
my $previous = {
  phase            => 'Running',
  managedResources => [ {%deployment_nats}, {%service_old} ]
};

subtest 'first step: deploy, Pending' => sub {
  my ( $comb, $k8s ) = comb( offers => [ { name => 'client', port => 4222 } ] );
  my $status = reconciled($comb);
  isa_ok $status, 'Kubernetes::Comb::CRD::CombStatus';
  is $status->phase, 'Pending', 'Pending';
  is_deeply [ map { $_->[0]{kind}.'/'.$_->[0]{metadata}{name} } $k8s->calls_of('ensure') ],
    [ 'Deployment/nats' ], 'the manifests were applied';
  ok $k8s->object( Deployment => 'nats', namespace => 'platform' ), 'and are stored';
  is_deeply managed($status), [ {%deployment_nats} ], 'managedResources records them';

  my $ready = condition( $status, 'Ready' );
  is $ready->status, 'False', 'Ready is False';
  is $ready->reason, 'Deployed', '... because it was just deployed';
  like $ready->message, qr/applied 1 resource\(s\), not healthy yet/, '... saying so';
  is condition( $status, 'DependenciesReady' )->status, 'True', 'DependenciesReady';
  is condition( $status, 'ConfigReady' )->status, 'True', 'ConfigReady';

  is_deeply [ map { $_->TO_JSON } @{ $status->endpoints } ],
    [ { name => 'client', protocol => 'tcp', port => 4222, cluster => 'nats.platform.svc:4222' } ],
    'the resolved local endpoints are published';
  is $comb->recorded_status, $status, 'without a custom resource the status is kept in memory';
  ok !$k8s->calls_of('update_status'), 'and nothing is written';
};

subtest 'healthy: Running, nothing applied, managedResources carried forward' => sub {
  my ( $comb, $k8s ) = comb();
  reconciled($comb);
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  $k8s->clear_calls;

  my $status = reconciled($comb);
  is $status->phase, 'Running', 'Running';
  ok !$k8s->calls_of('ensure'), 'nothing applied';
  ok !$k8s->calls_of('delete'), 'nothing deleted';
  is_deeply managed($status), [ {%deployment_nats} ], 'managedResources carried forward';
  is condition( $status, 'Ready' )->status, 'True', 'Ready is True';
  is condition( $status, 'Ready' )->reason, 'Healthy', '... Healthy';
};

subtest 'unhealthy again: deployed again, the live problem in the message' => sub {
  my ( $comb, $k8s ) = comb();
  reconciled($comb);
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 0 } );
  $k8s->clear_calls;
  my $status = reconciled($comb);
  is $status->phase, 'Pending', 'Pending';
  is scalar $k8s->calls_of('ensure'), 1, 'applied again';
  like condition( $status, 'Ready' )->message, qr/Deployment nats: 0 of 1 ready/, 'with what the cluster showed';
};

subtest 'a reconcile after stop deploys again' => sub {
  my ( $comb, $k8s ) = comb();
  reconciled($comb);
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  is reconciled($comb)->phase, 'Running', 'running';
  $comb->stop->get;
  is $k8s->object( Deployment => 'nats', namespace => 'platform' )->spec->replicas, 0, 'stopped';

  my $status = reconciled($comb);
  is $status->phase, 'Pending', 'the next step deploys: Pending';
  isnt $k8s->object( Deployment => 'nats', namespace => 'platform' )->spec->replicas // 1, 0,
    'the manifest brought the replicas back';
};

my $daemonset = {
  apiVersion => 'apps/v1',
  kind       => 'DaemonSet',
  metadata   => { name => 'agent' },
  spec       => {
    selector => { matchLabels => { app => 'agent' } },
    template => { metadata => { labels => { app => 'agent' } }, spec => { containers => [ { name => 'a', image => 'img' } ] } }
  }
};

subtest 'a reconcile after stop deploys again, with a DaemonSet stop leaves running' => sub {
  my ( $comb, $k8s ) = comb( parts => [ deployment('nats'), $daemonset ] );
  reconciled($comb);
  set_status( $k8s, Deployment => 'nats', { replicas => 1, readyReplicas => 1 } );
  set_status( $k8s, DaemonSet => 'agent', { desiredNumberScheduled => 1, numberReady => 1,
    currentNumberScheduled => 1, numberMisscheduled => 0 } );
  is reconciled($comb)->phase, 'Running', 'running';
  $comb->stop->get;
  set_status( $k8s, Deployment => 'nats', { replicas => 0 } );
  $k8s->clear_calls;

  my $status = reconciled($comb);
  is $status->phase, 'Pending', 'the next step deploys: Pending';
  like condition( $status, 'Ready' )->message, qr/not healthy yet \(stopped\)/, '... because it was stopped';
  is_deeply [ map { $_->[0]{kind} } $k8s->calls_of('ensure') ], [qw( Deployment DaemonSet )], 'applied';
  isnt $k8s->object( Deployment => 'nats', namespace => 'platform' )->spec->replicas // 1, 0,
    'the manifest brought the replicas back';
};

subtest 'a Deployment scaled to 0 by hand is scaled back' => sub {
  my ( $comb, $k8s ) = comb( parts => [ deployment('nats'), deployment('nats-web') ] );
  reconciled($comb);
  set_status( $k8s, Deployment => $_, { replicas => 1, readyReplicas => 1 } ) for qw( nats nats-web );
  is reconciled($comb)->phase, 'Running', 'running';
  $k8s->patch( 'Deployment', 'nats-web', namespace => 'platform', patch => { spec => { replicas => 0 } } )->get;
  set_status( $k8s, Deployment => 'nats-web', { replicas => 0 } );
  $k8s->clear_calls;

  my $status = reconciled($comb);
  is $status->phase, 'Pending', 'short of replicas: deployed, Pending';
  like condition( $status, 'Ready' )->message, qr/Deployment nats-web: 0 of 1 ready \(scaled to 0\)/, '... saying why';
  is scalar $k8s->calls_of('ensure'), 2, 'applied';
  isnt $k8s->object( Deployment => 'nats-web', namespace => 'platform' )->spec->replicas // 1, 0,
    'scaled back';
};

subtest 'a manifest at 0 replicas: Running at 0, no deploy every step' => sub {
  my $resting = deployment('nats');
  $resting->{spec}{replicas} = 0;
  my ( $comb, $k8s ) = comb( parts => [ $resting ] );
  reconciled($comb);
  $k8s->clear_calls;
  my $status = reconciled($comb);
  is $status->phase, 'Running', 'Running';
  ok !$k8s->calls_of('ensure'), 'nothing applied';
};

subtest 'a reconcile during a rolling restart keeps it' => sub {
  my ( $comb, $k8s ) = comb();
  reconciled($comb);
  $comb->restart->get;
  my $at = sub {
    my $template = $k8s->object( Deployment => 'nats', namespace => 'platform' )->TO_JSON->{spec}{template};
    return ( $template->{metadata}{annotations} // {} )->{'comb.internal/restartedAt'};
  };
  my $restarted = $at->();
  ok defined $restarted, 'restarted';
  $k8s->clear_calls;

  # the rollout is under way: not all replicas ready
  is reconciled($comb)->phase, 'Pending', 'mid-rollout: deployed, Pending';
  my ( $sent ) = map { $_->[0] } $k8s->calls_of('ensure');
  is $sent->{spec}{template}{metadata}{annotations}{'comb.internal/restartedAt'}, $restarted,
    'the applied manifest carries the restart over';
  is $at->(), $restarted, 'so the Pods are not rolled once more';
  is_deeply [ map { $_->[0] } $k8s->calls_of('list') ], [ 'apps/v1/Deployment', 'v1/Pod' ],
    'from the objects the status read already fetched';
};

subtest 'Disabled' => sub {
  my ( $off, $k8s ) = cr_comb( spec => { enabled => 0 }, status => $previous );
  my $status = reconciled($off);
  is $status->phase, 'Disabled', 'spec.enabled false: Disabled';
  is condition( $status, 'Ready' )->reason, 'Disabled', 'Ready says Disabled';
  is condition( $status, 'Ready' )->message, 'spec.enabled is false', '... and why';
  is condition( $status, $_ )->status, 'Unknown', $_.' not checked' for qw( DependenciesReady ConfigReady );
  is condition( $status, 'DependenciesReady' )->reason, 'NotChecked', '... NotChecked';
  ok !$k8s->calls_of($_), 'no '.$_ for qw( ensure delete patch list get );
  is_deeply managed($status), [ {%deployment_nats}, {%service_old} ], 'managedResources carried forward';

  my ( $optional ) = cr_comb( optional => 1 );
  my $auto_off = reconciled($optional);
  is $auto_off->phase, 'Disabled', 'optional and enabled unset: Disabled';
  like condition( $auto_off, 'Ready' )->message, qr/is optional and spec\.enabled is not set/, '... saying so';

  is reconciled( ( cr_comb( optional => 1, spec => { enabled => 1 } ) )[0] )->phase, 'Pending',
    'optional and enabled: runs';
  is reconciled( ( cr_comb() )[0] )->phase, 'Pending', 'not optional, enabled unset: runs';
  is reconciled( ( comb( optional => 1 ) )[0] )->phase, 'Disabled', 'optional without a custom resource: Disabled';
  ok !TestComb::Configurable->optional, 'optional works as class method';
  ok !Kubernetes::Comb->optional, 'and is false by default';
};

subtest 'Disabled leaves what runs alone' => sub {
  my ( $running, $k8s ) = comb();
  reconciled($running);
  my ( $off ) = cr_comb( k8s => $k8s, spec => { enabled => 0 } );
  is reconciled($off)->phase, 'Disabled', 'Disabled';
  ok $k8s->object( Deployment => 'nats', namespace => 'platform' ), 'the Deployment is still there';
};

subtest 'Blocked' => sub {
  my ( $no_resolver, $k8s ) = cr_comb( spec => { dependsOn => [ 'db' ] }, status => $previous );
  my $status = reconciled($no_resolver);
  is $status->phase, 'Blocked', 'dependencies but no resolver: Blocked';
  is condition( $status, 'Ready' )->reason, 'NoResolver', '... NoResolver';
  is condition( $status, 'DependenciesReady' )->status, 'False', 'DependenciesReady False';
  is condition( $status, 'ConfigReady' )->status, 'Unknown', 'ConfigReady not checked';
  ok !$k8s->calls_of('ensure'), 'nothing applied';
  is_deeply managed($status), [ {%deployment_nats}, {%service_old} ], 'managedResources carried forward';

  my @asked;
  my ( $missing ) = cr_comb(
    spec     => { dependsOn => [ 'db', 'other/cache' ] },
    resolver => sub { push @asked, [@_]; return }
  );
  $status = reconciled($missing);
  is $status->phase, 'Blocked', 'resolver finds nothing: Blocked';
  is condition( $status, 'Ready' )->reason, 'DependencyNotFound', '... DependencyNotFound';
  is condition( $status, 'Ready' )->message, 'dependency db not found; dependency other/cache not found',
    'every problem in the message';
  is_deeply [ map { $_->[0] } @asked ], [ 'db', 'other/cache' ], 'the resolver gets the references as written';
  is $asked[0][1], $missing, '... and the Comb';

  my ( $db, $db_k8s ) = comb( name => 'db' );   # never deployed
  my ( $waiting ) = cr_comb( spec => { dependsOn => [ 'db' ] }, resolver => sub { $db } );
  $status = reconciled($waiting);
  is $status->phase, 'Blocked', 'dependency not healthy: Blocked';
  is condition( $status, 'Ready' )->reason, 'DependencyNotReady', '... DependencyNotReady';
  is condition( $status, 'Ready' )->message, 'dependency db is not healthy', '... naming it';

  $db_k8s->fail_on( list => 'connection refused' );
  $status = reconciled($waiting);
  is $status->phase, 'Blocked', 'dependency health fails: Blocked';
  like condition( $status, 'Ready' )->message, qr/dependency db is not healthy: connection refused/, '... with why';

  my ( $dying ) = cr_comb( spec => { dependsOn => [ 'db' ] }, resolver => sub { die "registry down\n" } );
  $status = reconciled($dying);
  is $status->phase, 'Blocked', 'a dying resolver: Blocked';
  is condition( $status, 'Ready' )->reason, 'ResolverFailed', '... ResolverFailed';
  like condition( $status, 'Ready' )->message, qr/looking up db failed: registry down/, '... with the error';

  my ( $odd ) = cr_comb( spec => { dependsOn => [ 'db' ] }, resolver => sub { 'db' } );
  $status = reconciled($odd);
  is $status->phase, 'Blocked', 'the resolver returns no Comb: Blocked';
  is condition( $status, 'Ready' )->reason, 'DependencyInvalid', '... DependencyInvalid';
};

subtest 'dependencies healthy: on to the next step' => sub {
  my ( $db ) = comb( name => 'db', parts => [] );   # nothing to run: healthy
  my ( $comb, $k8s ) = cr_comb( spec => { dependsOn => [ 'db' ] }, resolver => sub { $db } );
  my $status = reconciled($comb);
  is $status->phase, 'Pending', 'deployed';
  is condition( $status, 'DependenciesReady' )->status, 'True', 'DependenciesReady True';
};

subtest 'NeedsConfig' => sub {
  my ( $comb, $k8s ) = cr_comb( missing => [ 'secret nats-auth', 'config key cluster' ], status => $previous );
  my $status = reconciled($comb);
  is $status->phase, 'NeedsConfig', 'NeedsConfig';
  is condition( $status, 'Ready' )->reason, 'MissingPrerequisites', 'MissingPrerequisites';
  is condition( $status, 'ConfigReady' )->status, 'False', 'ConfigReady False';
  is condition( $status, 'ConfigReady' )->message, 'missing: secret nats-auth; config key cluster',
    'what is missing';
  is condition( $status, 'DependenciesReady' )->status, 'True', 'dependencies were checked before';
  ok !$k8s->calls_of('ensure'), 'nothing applied';
  is_deeply managed($status), [ {%deployment_nats}, {%service_old} ], 'managedResources carried forward';

  my ( $async ) = cr_comb( missing => sub { Future->done('secret nats-auth') } );
  is reconciled($async)->phase, 'NeedsConfig', 'check may return a Future';

  my $checked = 0;
  my ( $blocked ) = cr_comb( spec => { dependsOn => [ 'db' ] }, missing => sub { $checked++; () } );
  is reconciled($blocked)->phase, 'Blocked', 'Blocked comes first';
  is $checked, 0, 'check is not asked then';
};

subtest 'Error' => sub {
  my ( $comb, $k8s ) = comb( parts => sub { die "no manifests today\n" } );
  $comb->_memory_status( Kubernetes::Comb::CRD::CombStatus->new(%$previous) );
  my $status = reconciled($comb);
  is $status->phase, 'Error', 'manifests dying: Error';
  is condition( $status, 'Ready' )->reason, 'ManifestsFailed', '... ManifestsFailed';
  like condition( $status, 'Ready' )->message, qr/no manifests today/, '... with the error';
  is_deeply managed($status), [ {%deployment_nats}, {%service_old} ], 'managedResources carried forward';

  ( $comb ) = comb( parts => [ { kind => 'Deployment' } ] );
  $status = reconciled($comb);
  is condition( $status, 'Ready' )->reason, 'ManifestsFailed', 'a manifest that does not render: ManifestsFailed';
  like condition( $status, 'Ready' )->message, qr/has no metadata\.name/, '... saying why';

  ( $comb ) = comb( missing => sub { die "vault sealed\n" } );
  $status = reconciled($comb);
  is $status->phase, 'Error', 'check dying: Error';
  is condition( $status, 'Ready' )->reason, 'CheckFailed', '... CheckFailed';
  is condition( $status, 'ConfigReady' )->status, 'Unknown', 'ConfigReady Unknown';
  like condition( $status, 'ConfigReady' )->message, qr/vault sealed/, '... with the error';

  ( $comb, $k8s ) = comb();
  $k8s->fail_on( list => 'connection refused' );
  $status = reconciled($comb);
  is $status->phase, 'Error', 'the live status cannot be read: Error';
  is condition( $status, 'Ready' )->reason, 'StatusFailed', '... StatusFailed';
  like condition( $status, 'Ready' )->message, qr/connection refused/, '... with the error';

  ( $comb ) = comb( offers => [ { name => 'client', port => 4222, sevice => 'typo' } ] );
  $status = reconciled($comb);
  is $status->phase, 'Error', 'endpoints that do not resolve: Error';
  is condition( $status, 'Ready' )->reason, 'EndpointsFailed', '... EndpointsFailed';
};

subtest 'an error text loses where Perl raised it' => sub {
  open my $fh, '<', \"one line\n" or die $!;
  my %dying = (
    'die'                => [ sub { die 'vault sealed' },                                   ' at FILE line N.' ],
    'croak'              => [ sub { croak('vault sealed') },                                ' at FILE line N.' ],
    'die after reading'  => [ sub { my $line = <$fh>; die 'vault sealed' },                 ', <$fh> line 1.' ],
    'die in string eval' => [ sub { eval q{die 'vault sealed'}; die $@ },                   ' at (eval N) line 1, <$fh> line 1.' ],
    'failed Future'      => [ sub { Future->fail("vault sealed at lib/Vault.pm line 7.\n") }, ' at FILE line N.' ]
  );
  for my $what ( sort keys %dying ) {
    my ( $hook, $suffix ) = @{ $dying{$what} };
    my ( $comb ) = comb( missing => $hook );
    my $status = reconciled($comb);
    is condition( $status, 'Ready' )->message, 'check failed: vault sealed',
      $what.': Ready without "'.$suffix.'"';
    is condition( $status, 'ConfigReady' )->message, 'check failed: vault sealed',
      $what.': ConfigReady too';
  }
};

subtest 'deploy failing half-way' => sub {
  my ( $comb, $k8s ) = comb( parts => [ deployment('nats'), service('nats'), service('nats-web') ] );
  $comb->_memory_status( Kubernetes::Comb::CRD::CombStatus->new(%$previous) );
  $k8s->add( service( 'old', namespace => 'platform', labels => { comb_labels('nats') } ) );
  $k8s->fail_on( ensure => 'quota exceeded', when => sub { $_[0]{kind} eq 'Service' } );

  my $status = reconciled($comb);
  is $status->phase, 'Error', 'Error';
  is condition( $status, 'Ready' )->reason, 'DeployFailed', '... DeployFailed';
  like condition( $status, 'Ready' )->message, qr/ensure Service nats: quota exceeded/, '... naming what failed';
  is_deeply managed($status), [ {%deployment_nats}, {%service_old} ],
    'managedResources: what was applied, plus what was recorded before';
  ok !$k8s->calls_of('delete'), 'nothing pruned';
  ok $k8s->object( Service => 'old', namespace => 'platform' ), 'the orphan is still there';
};

subtest 'a broken client' => sub {
  my ( $comb ) = comb( class => 'TestComb::NoClient', k8s => undef );
  my $f = $comb->reconcile;
  ok $f->is_done, 'the client cannot be built: still done';
  is $f->get->phase, 'Error', 'Error';
  like condition( $f->get, 'Ready' )->message, qr/no kubeconfig here/, 'with the error';

  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my ( $cr_comb ) = cr_comb( k8s => $k8s );
  $k8s->fail_on( '*' => 'connection refused' );
  $f = $cr_comb->reconcile;
  ok $f->is_done, 'every request fails: still done';
  is $f->get->phase, 'Error', 'Error';
  is condition( $f->get, 'StatusWritten' )->status, 'False', 'and the status could not be written';
  is $cr_comb->recorded_status, $f->get, 'it is kept in memory';
};

subtest 'the Future is always done' => sub {
  my %broken = (
    'manifests die'       => [ parts    => sub { die "boom\n" } ],
    'check dies'          => [ missing  => sub { die "boom\n" } ],
    'resolver dies'       => [ resolver => sub { die "boom\n" }, needs => [ 'db' ] ],
    'upstream dies'       => [ upstream => sub { die "boom\n" } ],
    'check fails'         => [ missing  => sub { Future->fail("boom\n") } ],
    'no name'             => [ name     => undef ],
    'status cannot build' => [ class    => 'TestComb::BrokenRecord' ]
  );
  for my $what ( sort keys %broken ) {
    my %args = @{ $broken{$what} };
    my $name = exists $args{name} ? delete $args{name} : 'nats';
    my $class = delete $args{class} // 'TestComb::Configurable';
    my $comb = $class->new(
      ( defined $name ? ( name => $name ) : () ),
      namespace => 'platform',
      k8s       => Kubernetes::Comb::Client::Fake->new,
      parts     => [ deployment('nats') ],
      %args
    );
    my $f = $comb->reconcile;
    ok $f->is_done && !$f->is_failed, $what.': done';
    like $f->get->phase, qr/\A(?:Error|Blocked)\z/, $what.': '.$f->get->phase;
  }
  my ( $broken ) = comb( class => 'TestComb::BrokenRecord' );
  like condition( $broken->reconcile->get, 'Ready' )->message, qr/recording the status failed: cannot build a status/,
    'when even the status cannot be built, the bare minimum says why';
};

subtest 'an asynchronous hook' => sub {
  my $pending = Future->new;
  my ( $comb ) = comb( missing => sub { $pending } );
  my $f = $comb->reconcile;
  ok !$f->is_ready, 'waits for the hook';
  $pending->done;
  ok $f->is_done, 'done once it is';
  is $f->get->phase, 'Pending', 'and went on';
};

done_testing;
