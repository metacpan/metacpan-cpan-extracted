use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Kubernetes::Comb;
use Kubernetes::Comb::Client::Fake;
use Kubernetes::Comb::CRD::CombStatus;
use TestComb::Configurable;
use TestComb::Fixtures qw( comb_labels deployment service set_status );

my %labels = comb_labels('nats');

my %deployment_nats = ( apiVersion => 'apps/v1', kind => 'Deployment', namespace => 'platform', name => 'nats' );

# nats, rendering one Deployment, with what an earlier step recorded.
sub comb {
  my ( @recorded ) = @_;
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my $comb = TestComb::Configurable->new(
    name      => 'nats',
    namespace => 'platform',
    k8s       => $k8s,
    parts     => [ deployment('nats') ]
  );
  $comb->_memory_status( Kubernetes::Comb::CRD::CombStatus->new(
    phase            => 'Pending',
    managedResources => [ {%deployment_nats}, @recorded ]
  ) );
  return ( $comb, $k8s );
}

sub managed {
  my ( $status ) = @_;
  return [ map { $_->TO_JSON } @{ $status->managedResources // [] } ];
}

sub ready_message {
  my ( $status ) = @_;
  my ( $ready ) = grep { $_->type eq 'Ready' } @{ $status->conditions };
  return $ready->message;
}

sub deleted {
  my ( $k8s ) = @_;
  return [ map { $_->[0]->kind.'/'.$_->[0]->metadata->name } $k8s->calls_of('delete') ];
}

subtest 'an orphan that carries the label is deleted' => sub {
  my %old = ( apiVersion => 'v1', kind => 'Service', namespace => 'platform', name => 'old' );
  my ( $comb, $k8s ) = comb( {%old} );
  $k8s->add( service( 'old', namespace => 'platform', labels => {%labels} ) );

  my $status = $comb->reconcile->get;
  is $status->phase, 'Pending', 'Pending';
  is_deeply deleted($k8s), [ 'Service/old' ], 'deleted';
  ok !$k8s->object( Service => 'old', namespace => 'platform' ), 'gone from the cluster';
  is_deeply managed($status), [ {%deployment_nats} ], 'and from managedResources';
  unlike ready_message($status), qr/old/, 'nothing to report';
};

subtest 'an orphan is deleted with what it owns' => sub {
  my %job = ( apiVersion => 'batch/v1', kind => 'Job', namespace => 'platform', name => 'nats-init' );
  my ( $comb, $k8s ) = comb( {%job} );
  $k8s->add( {
    apiVersion => 'batch/v1',
    kind       => 'Job',
    metadata   => { name => 'nats-init', namespace => 'platform', labels => {%labels} },
    spec       => { template => { spec => { restartPolicy => 'Never', containers => [ { name => 'init', image => 'img' } ] } } }
  } );

  my $status = $comb->reconcile->get;
  is $status->phase, 'Pending', 'Pending';
  is_deeply [ map { [ $_->[0]->kind.'/'.$_->[0]->metadata->name, @{$_}[ 1 .. $#$_ ] ] } $k8s->calls_of('delete') ],
    [ [ 'Job/nats-init', propagationPolicy => 'Background' ] ],
    'the pruned Job is deleted with propagationPolicy Background: its Pods go too';
  ok !$k8s->object( Job => 'nats-init', namespace => 'platform' ), 'gone from the cluster';
  is_deeply managed($status), [ {%deployment_nats} ], 'and from managedResources';
};

subtest 'an orphan without the label is never deleted' => sub {
  my %shared = ( apiVersion => 'v1', kind => 'Service', namespace => 'platform', name => 'shared' );
  my %taken  = ( apiVersion => 'v1', kind => 'Service', namespace => 'platform', name => 'taken' );
  my ( $comb, $k8s ) = comb( {%shared}, {%taken} );
  $k8s->add(
    service( 'shared', namespace => 'platform' ),
    service( 'taken', namespace => 'platform', labels => { comb_labels('other') } )
  );

  my $status = $comb->reconcile->get;
  is_deeply deleted($k8s), [], 'nothing deleted';
  ok $k8s->object( Service => $_, namespace => 'platform' ), $_.' is still there' for qw( shared taken );
  is_deeply managed($status), [ {%deployment_nats} ], 'dropped from managedResources';
  like ready_message($status), qr/left Service shared alone: it no longer carries comb\.internal\/comb=nats/,
    'reported: label gone';
  like ready_message($status), qr/left Service taken alone/, 'reported: another Comb\'s';
};

subtest 'an orphan that is already gone is dropped' => sub {
  my %gone = ( apiVersion => 'v1', kind => 'Secret', namespace => 'platform', name => 'gone' );
  my ( $comb, $k8s ) = comb( {%gone} );
  my $status = $comb->reconcile->get;
  is_deeply deleted($k8s), [], 'nothing to delete';
  is_deeply managed($status), [ {%deployment_nats} ], 'dropped from managedResources';
  unlike ready_message($status), qr/gone/, 'nothing to report';
};

subtest 'a new API version is no orphan' => sub {
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my $comb = TestComb::Configurable->new(
    name      => 'nats',
    namespace => 'platform',
    k8s       => $k8s,
    parts     => [ deployment('nats') ]
  );
  $comb->_memory_status( Kubernetes::Comb::CRD::CombStatus->new(
    phase            => 'Pending',
    managedResources => [ { %deployment_nats, apiVersion => 'apps/v1beta1' } ]
  ) );
  my $status = $comb->reconcile->get;
  is_deeply deleted($k8s), [], 'nothing deleted';
  ok !grep( { $_->[0] =~ /v1beta1/ } $k8s->calls_of('list') ), 'not even looked for';
  is_deeply managed($status), [ {%deployment_nats} ], 'recorded under the version applied now';
};

subtest 'a failed delete stays for the next step' => sub {
  my %old = ( apiVersion => 'v1', kind => 'Service', namespace => 'platform', name => 'old' );
  my ( $comb, $k8s ) = comb( {%old} );
  $k8s->add( service( 'old', namespace => 'platform', labels => {%labels} ) );
  $k8s->fail_on( delete => 'forbidden', times => 1 );

  my $status = $comb->reconcile->get;
  is $status->phase, 'Pending', 'still Pending';
  is_deeply managed($status), [ {%deployment_nats}, {%old} ], 'kept in managedResources';
  like ready_message($status), qr/deleting Service old failed: forbidden/, 'reported';
  ok $k8s->object( Service => 'old', namespace => 'platform' ), 'still there';

  $status = $comb->reconcile->get;
  ok !$k8s->object( Service => 'old', namespace => 'platform' ), 'the next deploy deletes it';
  is_deeply managed($status), [ {%deployment_nats} ], 'and drops it';
};

subtest 'an orphan that cannot be checked stays' => sub {
  my %old = ( apiVersion => 'v1', kind => 'Service', namespace => 'platform', name => 'old' );
  my ( $comb, $k8s ) = comb( {%old} );
  $k8s->add( service( 'old', namespace => 'platform', labels => {%labels} ) );
  $k8s->fail_on( list => 'connection reset', when => sub { $_[0] eq 'v1/Service' } );

  my $status = $comb->reconcile->get;
  is_deeply deleted($k8s), [], 'nothing deleted';
  is_deeply managed($status), [ {%deployment_nats}, {%old} ], 'kept in managedResources';
  like ready_message($status), qr/could not check Service old for pruning: connection reset/, 'reported';
};

subtest 'a cluster-scoped orphan is left in place' => sub {
  my %role  = ( apiVersion => 'rbac.authorization.k8s.io/v1', kind => 'ClusterRole', name => 'nats-reader' );
  my %space = ( apiVersion => 'v1', kind => 'Namespace', name => 'nats-extra' );
  # a cluster-scoped manifest that named a namespace anyway
  my %binding = ( apiVersion => 'rbac.authorization.k8s.io/v1', kind => 'ClusterRoleBinding',
    namespace => 'platform', name => 'nats-reader' );
  my ( $comb, $k8s ) = comb( {%role}, {%space}, {%binding} );
  $k8s->add(
    {
      apiVersion => 'rbac.authorization.k8s.io/v1',
      kind       => 'ClusterRole',
      metadata   => { name => 'nats-reader', labels => {%labels} },
      rules      => []
    },
    { apiVersion => 'v1', kind => 'Namespace', metadata => { name => 'nats-extra', labels => {%labels} } }
  );
  my $status = $comb->reconcile->get;
  is $status->phase, 'Pending', 'Pending';
  is_deeply deleted($k8s), [], 'nothing deleted';
  ok $k8s->object( ClusterRole => 'nats-reader' ), 'the ClusterRole is still there';
  ok $k8s->object( Namespace => 'nats-extra' ), 'the Namespace, with all in it, too';
  ok !grep( { $_->[0] =~ /Cluster|Namespace/ } $k8s->calls_of('list') ), 'not even looked for';
  is_deeply managed($status), [ {%deployment_nats} ], 'dropped from managedResources';
  like ready_message($status), qr/left ClusterRole nats-reader in place: cluster-scoped, never pruned automatically/,
    'reported: left in place';
  like ready_message($status), qr/left Namespace nats-extra in place/, '... each of them';
  like ready_message($status), qr/left ClusterRoleBinding nats-reader in place/, '... a recorded namespace changes nothing';
};

subtest 'a same-named Comb in another namespace keeps what it applied last' => sub {
  # nats in getty and in dev, the layers in one cluster, both with a Service
  # in namespace shared
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my %comb = map { $_ => TestComb::Configurable->new(
    name      => 'nats',
    namespace => $_,
    k8s       => $k8s,
    parts     => [ deployment('nats'), service( 'nats-shared', namespace => 'shared' ) ]
  ) } qw( getty dev );
  $comb{getty}->reconcile->get;
  $comb{dev}->reconcile->get;
  is_deeply $k8s->object( Service => 'nats-shared', namespace => 'shared' )->metadata->labels,
    { comb_labels( 'nats', 'dev' ) }, 'dev applied it last: labelled as dev\'s';

  $k8s->clear_calls;
  $comb{getty}->parts( [ deployment('nats') ] );
  my $status = $comb{getty}->reconcile->get;
  is_deeply deleted($k8s), [], 'getty deletes nothing';
  ok $k8s->object( Service => 'nats-shared', namespace => 'shared' ), 'dev\'s Service is still there';
  like ready_message($status),
    qr/left Service nats-shared alone: it no longer carries comb\.internal\/comb=nats,comb\.internal\/comb-namespace=getty/,
    'reported: no longer getty\'s';
  is_deeply managed($status), [ { %deployment_nats, namespace => 'getty' } ], 'dropped from getty\'s record';

  $comb{dev}->parts( [ deployment('nats') ] );
  $comb{dev}->reconcile->get;
  is_deeply deleted($k8s), [ 'Service/nats-shared' ], 'the Comb that applied it last prunes it';
};

subtest 'layers in one cluster: a borrowing layer leaves the other\'s cluster-scoped parts' => sub {
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my %role = (
    apiVersion => 'rbac.authorization.k8s.io/v1',
    kind       => 'ClusterRole',
    metadata   => { name => 'nats-reader' },
    rules      => []
  );
  my $answer = [];
  my %comb = map { $_ => TestComb::Configurable->new(
    name      => 'nats',
    namespace => $_,
    k8s       => $k8s,
    parts     => [ service('nats'), {%role} ],
    offers    => [ { name => 'client', port => 4222 } ],
    ( $_ eq 'getty' ? ( upstream => sub { @$answer } ) : () )
  ) } qw( dev getty );
  $comb{$_}->reconcile->get for qw( dev getty );
  is $comb{dev}->status->get->{phase}, 'Running', 'both deployed, dev Running';

  # the developer's layer now borrows nats from dev
  @$answer = ( Static => ( endpoints => [ { name => 'client', port => 4222, cluster => 'nats.dev.svc:4222' } ] ) );
  my $status = $comb{getty}->reconcile->get;
  is $status->phase, 'Running', 'getty borrows';
  ok $k8s->object( ClusterRole => 'nats-reader' ), 'the ClusterRole dev still renders is still there';
  like ready_message($status), qr/left ClusterRole nats-reader in place/, 'getty says so';
  is $comb{dev}->status->get->{phase}, 'Running', 'dev stays Running';
};

subtest 'a healthy Comb prunes too: Running' => sub {
  my %old = ( apiVersion => 'v1', kind => 'Service', namespace => 'platform', name => 'old' );
  my ( $comb, $k8s ) = comb( {%old} );
  $k8s->add( service( 'old', namespace => 'platform', labels => {%labels} ) );
  $comb->deploy->get;
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  $k8s->clear_calls;

  my $status = $comb->reconcile->get;
  is $status->phase, 'Running', 'healthy: Running';
  like ready_message($status), qr/\Ahealthy; the record differed from the manifests: applied 1 resource\(s\)\z/,
    'saying why it deployed';
  is scalar $k8s->calls_of('ensure'), 1, 'deployed';
  is_deeply deleted($k8s), [ 'Service/old' ], 'the orphan is pruned';
  is_deeply managed($status), [ {%deployment_nats} ], 'and no longer recorded';

  $k8s->clear_calls;
  $status = $comb->reconcile->get;
  is $status->phase, 'Running', 'the record matches: Running';
  ok !$k8s->calls_of('ensure'), 'nothing applied';
  is ready_message($status), 'healthy', 'nothing to report';
};

subtest 'a failed delete is retried while healthy' => sub {
  my %old = ( apiVersion => 'v1', kind => 'Service', namespace => 'platform', name => 'old' );
  my ( $comb, $k8s ) = comb( {%old} );
  $k8s->add( service( 'old', namespace => 'platform', labels => {%labels} ) );
  $comb->deploy->get;
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  $k8s->fail_on( delete => 'forbidden', times => 1 );

  my $status = $comb->reconcile->get;
  is $status->phase, 'Running', 'still Running';
  like ready_message($status), qr/deleting Service old failed: forbidden/, 'reported';
  is_deeply managed($status), [ {%deployment_nats}, {%old} ], 'kept in managedResources';

  $status = $comb->reconcile->get;
  ok !$k8s->object( Service => 'old', namespace => 'platform' ), 'the next step deletes it';
  is_deeply managed($status), [ {%deployment_nats} ], 'and drops it';
  is $status->phase, 'Running', 'Running throughout';
};

subtest 'a resource a healthy Comb drops from its manifests is pruned' => sub {
  my %web = ( apiVersion => 'v1', kind => 'Service', namespace => 'platform', name => 'nats' );
  my ( $comb, $k8s ) = comb();
  $comb->parts( [ deployment('nats'), service('nats') ] );
  $comb->reconcile->get;
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  my $status = $comb->reconcile->get;
  is $status->phase, 'Running', 'Running';
  is_deeply managed($status), [ {%deployment_nats}, {%web} ], 'recorded';
  $k8s->clear_calls;

  $comb->parts( [ deployment('nats') ] );
  $status = $comb->reconcile->get;
  is $status->phase, 'Running', 'still Running';
  is_deeply deleted($k8s), [ 'Service/nats' ], 'dropped from the manifests: deleted';
  is_deeply managed($status), [ {%deployment_nats} ], 'and no longer recorded';
};

subtest 'a healthy Comb with nothing recorded records what it runs' => sub {
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my $comb = TestComb::Configurable->new(
    name      => 'nats',
    namespace => 'platform',
    k8s       => $k8s,
    parts     => [ deployment('nats') ]
  );
  $comb->deploy->get;
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  my $status = $comb->reconcile->get;
  is $status->phase, 'Running', 'Running';
  is_deeply managed($status), [ {%deployment_nats} ], 'recorded';
};

subtest 'a resource the manifests drop is pruned' => sub {
  my %web = ( apiVersion => 'v1', kind => 'Service', namespace => 'platform', name => 'nats' );
  my ( $comb, $k8s ) = comb();
  $comb->parts( [ deployment('nats'), service('nats') ] );
  my $status = $comb->reconcile->get;
  is_deeply managed($status), [ {%deployment_nats}, {%web} ], 'recorded';
  $k8s->clear_calls;

  $comb->parts( [ deployment('nats') ] );
  $status = $comb->reconcile->get;
  is_deeply deleted($k8s), [ 'Service/nats' ], 'dropped from the manifests: deleted';
  is_deeply managed($status), [ {%deployment_nats} ], 'and no longer recorded';
};

done_testing;
