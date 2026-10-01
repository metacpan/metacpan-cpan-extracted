use strict;
use warnings;
use Test::More;

use lib 't/lib';
use IO::K8s;
use JSON::MaybeXS qw( JSON );
use Kubernetes::Comb;
use Kubernetes::Comb::Client::Fake;
use Kubernetes::Comb::CRD::CombStatus;
use TestComb::Configurable;
use TestComb::Fixtures qw( comb_cr comb_labels deployment service set_status );

# The applied digest: deploy puts it on every resource, the local path of
# reconcile compares it with what the Comb renders now.

my $key = 'comb.internal/applied-digest';
my $restarted_at = 'comb.internal/restartedAt';

# nats in platform, without a custom resource: a Deployment and a Service.
sub comb {
  my ( %args ) = @_;
  my $k8s = delete $args{k8s} // Kubernetes::Comb::Client::Fake->new;
  return ( TestComb::Configurable->new(
    name      => 'nats',
    namespace => 'platform',
    k8s       => $k8s,
    parts     => [ deployment('nats'), service('nats') ],
    %args
  ), $k8s );
}

sub with_image {
  my ( $image, $name ) = @_;
  my $manifest = deployment( $name // 'nats' );
  $manifest->{spec}{template}{spec}{containers}[0]{image} = $image;
  return $manifest;
}

sub claim {
  my ( $name, $size ) = @_;
  return {
    apiVersion => 'v1',
    kind       => 'PersistentVolumeClaim',
    metadata   => { name => $name },
    spec       => { accessModes => [ 'ReadWriteOnce' ], resources => { requests => { storage => $size } } }
  };
}

sub job {
  my ( $name, $image ) = @_;
  return {
    apiVersion => 'batch/v1',
    kind       => 'Job',
    metadata   => { name => $name },
    spec       => { template => { spec => {
      restartPolicy => 'Never',
      containers    => [ { name => 'migrate', image => $image } ]
    } } }
  };
}

sub reconciled {
  my ( $comb ) = @_;
  my $f = $comb->reconcile;
  ok $f->is_done, 'the reconcile Future is done';
  return $f->get;
}

sub ready {
  my ( $status ) = @_;
  my ( $ready ) = grep { $_->type eq 'Ready' } @{ $status->conditions };
  return $ready;
}

sub managed { [ map { $_->TO_JSON } @{ $_[0]->managedResources // [] } ] }
sub ensured { [ map { $_->[0]{kind}.'/'.$_->[0]{metadata}{name} } $_[0]->calls_of('ensure') ] }
sub deleted { [ map { $_->[0]->kind.'/'.$_->[0]->metadata->name } $_[0]->calls_of('delete') ] }

sub stored {
  my ( $k8s, $kind, $name, $namespace ) = @_;
  my $object = $k8s->object( $kind, $name, namespace => $namespace // 'platform' );
  return $object ? $object->TO_JSON : undef;
}

sub digest_on {
  my ( $k8s, $kind, $name, $namespace ) = @_;
  my $object = stored( $k8s, $kind, $name, $namespace ) or return;
  return ( $object->{metadata}{annotations} // {} )->{$key};
}

# The stored object as the code before the digest applied it: without one.
sub strip_digest {
  my ( $k8s, $kind, $name ) = @_;
  my $object = stored( $k8s, $kind, $name );
  delete $object->{metadata}{annotations};
  $k8s->add($object);
  return;
}

# Deployed, the Deployment ready, one step taken: Running.
sub running {
  my ( %args ) = @_;
  my ( $comb, $k8s ) = comb(%args);
  reconciled($comb);
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  is reconciled($comb)->phase, 'Running', 'running';
  $k8s->clear_calls;
  return ( $comb, $k8s );
}

subtest 'deploy puts the digest on every resource' => sub {
  my @parts = ( deployment('nats'), IO::K8s->new->new_object( Service => service('nats') ) );
  my ( $comb, $k8s ) = comb( parts => [ @parts ] );
  can_ok $comb, 'applied_digest_annotation';
  is $comb->applied_digest_annotation, $key, 'the annotation key';
  my $prefixed = TestComb::Configurable->new( name => 'x', namespace => 'y', label_prefix => 'example.org/' );
  is $prefixed->applied_digest_annotation, 'example.org/applied-digest', '... follows label_prefix';

  $comb->deploy->get;
  my ( $deployment, $service ) = map { $_->[0] } $k8s->calls_of('ensure');
  my $on_service = ( $service->metadata->annotations // {} )->{$key};
  like $deployment->{metadata}{annotations}{$key}, qr/\Asha256:[0-9a-f]{64}\z/, 'a hashref manifest carries it';
  like $on_service, qr/\Asha256:[0-9a-f]{64}\z/, 'an IO::K8s manifest too';
  isnt $deployment->{metadata}{annotations}{$key}, $on_service, 'each its own';
  ok !exists $deployment->{spec}{template}{metadata}{annotations}, 'the Pod template carries none';
  is digest_on( $k8s, Deployment => 'nats' ), $deployment->{metadata}{annotations}{$key}, 'stored with it';
  is_deeply $parts[0], deployment('nats'), 'the manifest of the class is not changed';
};

subtest 'the digest is of what the Comb renders' => sub {
  my $digest = sub {
    my ( $manifest, %args ) = @_;
    my ( $comb ) = comb( parts => [ $manifest ], %args );
    my ( $item ) = $comb->_items($manifest);
    my $data = $item->{data};
    is $data->{metadata}{annotations}{$key}, $item->{digest}, 'the item knows the digest it carries';
    return $item->{digest};
  };
  my $plain = $digest->( deployment('nats') );
  is $digest->( deployment('nats') ), $plain, 'the same manifest: the same digest';
  isnt $digest->( with_image('img:2') ), $plain, 'another image: another digest';
  isnt $digest->( deployment('nats'), namespace => 'dev' ), $plain, 'another namespace: another digest';
  is $digest->( { %{ deployment('nats') }, apiVersion => undef } ), $plain,
    'the apiVersion the Comb fills in counts as rendered';
  is $digest->( IO::K8s->new->new_object( Deployment => deployment('nats') ) ),
    $digest->( IO::K8s->new->new_object( Deployment => deployment('nats') ) ), 'an IO::K8s manifest: stable';

  my $annotated = deployment('nats');
  $annotated->{metadata}{annotations} = { note => 'mine' };
  isnt $digest->($annotated), $plain, 'an annotation of the manifest counts';
  my $stale = deployment('nats');
  $stale->{metadata}{annotations} = { $key => 'sha256:stale' };
  is $digest->($stale), $plain, 'a digest the manifest brings along does not';
  my ( $comb ) = comb();
  is( ( $comb->_items($stale) )[0]{data}{metadata}{annotations}{$key}, $plain, '... and is replaced' );
  is_deeply( ( $comb->_items($annotated) )[0]{data}{metadata}{annotations},
    { note => 'mine', $key => $digest->($annotated) }, 'the annotations of the manifest stay' );
};

subtest 'the digest does not depend on how Perl holds a value' => sub {
  my $manifest = deployment('nats');
  $manifest->{spec}{replicas} = 2;
  $manifest->{spec}{template}{spec}{containers}[0]{ports} = [ { containerPort => '4222' } ];
  $manifest->{spec}{paused} = JSON->false;
  my ( $comb ) = comb( parts => [ $manifest ] );
  my $before = ( $comb->_items($manifest) )[0]{digest};

  # what any code reading the manifest may do to its scalars
  my $as_string = 'replicas: '.$manifest->{spec}{replicas};
  my $as_number = $manifest->{spec}{template}{spec}{containers}[0]{ports}[0]{containerPort} + 0;
  is( ( $comb->_items($manifest) )[0]{digest}, $before, 'a number used as a string, a string used as a number' );

  $manifest->{spec}{replicas} = '2';
  $manifest->{spec}{paused} = \0;
  is( ( $comb->_items($manifest) )[0]{digest}, $before, 'a number written as a string, a boolean as \0' );
  $manifest->{spec}{replicas} = 3;
  isnt( ( $comb->_items($manifest) )[0]{digest}, $before, 'another number is another digest' );
};

subtest 'healthy and applied as rendered: Running, nothing applied' => sub {
  my ( $comb, $k8s ) = running();
  my $status = reconciled($comb);
  is $status->phase, 'Running', 'Running';
  is ready($status)->message, 'healthy', 'healthy';
  is_deeply ensured($k8s), [], 'nothing applied';
  is_deeply deleted($k8s), [], 'nothing deleted';
};

subtest 'a manifest changed in content: applied, Pending, then Running' => sub {
  my ( $comb, $k8s ) = running();
  my $before = digest_on( $k8s, Deployment => 'nats' );
  $comb->parts( [ with_image('img:2'), service('nats') ] );

  my $status = reconciled($comb);
  is $status->phase, 'Pending', 'Pending';
  is ready($status)->reason, 'Deployed', 'Deployed';
  is ready($status)->message, 'applied 2 resource(s), rendered differently now: Deployment nats',
    'saying what changed';
  is_deeply ensured($k8s), [ 'Deployment/nats', 'Service/nats' ], 'applied';
  is stored( $k8s, Deployment => 'nats' )->{spec}{template}{spec}{containers}[0]{image}, 'img:2',
    'the new image reached the cluster';
  isnt digest_on( $k8s, Deployment => 'nats' ), $before, 'with its digest';
  is scalar @{ managed($status) }, 2, 'managedResources as before';

  $k8s->clear_calls;
  $status = reconciled($comb);
  is $status->phase, 'Running', 'the step after: Running';
  is_deeply ensured($k8s), [], 'nothing applied';
};

subtest 'a changed spec.config reaches the cluster' => sub {
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  $k8s->add( comb_cr( name => 'nats', class => 'TestComb::Configurable', spec => { config => { image => 'nats:2' } } ) );
  my $build = sub {
    TestComb::Configurable->new(
      crd   => $k8s->object( Comb => 'nats', namespace => 'platform' ),
      k8s   => $k8s,
      parts => sub { with_image( $_[0]->config->{image} ) }
    );
  };
  my $comb = $build->();
  reconciled($comb);
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  is reconciled($comb)->phase, 'Running', 'running';

  $k8s->patch( 'Comb', 'nats', namespace => 'platform',
    patch => { spec => { config => { image => 'nats:3' } } }, type => 'merge' )->get;
  $k8s->clear_calls;
  $comb = $build->();   # what a manager does on a changed custom resource
  my $status = reconciled($comb);
  is $status->phase, 'Pending', 'Pending';
  is_deeply ensured($k8s), [ 'Deployment/nats' ], 'applied';
  is stored( $k8s, Deployment => 'nats' )->{spec}{template}{spec}{containers}[0]{image}, 'nats:3',
    'the image from the new config';
  $k8s->clear_calls;
  is reconciled($comb)->phase, 'Running', 'the step after: Running';
  is_deeply ensured($k8s), [], 'nothing applied';
};

subtest 'live resources without a digest: one deploy, then quiet' => sub {
  my ( $comb, $k8s ) = running();
  strip_digest( $k8s, Deployment => 'nats' );
  strip_digest( $k8s, Service => 'nats' );
  ok !defined digest_on( $k8s, $_ => 'nats' ), $_.' as applied before there was a digest' for qw( Deployment Service );

  my $status = reconciled($comb);
  is $status->phase, 'Pending', 'Pending';
  is ready($status)->message, 'applied 2 resource(s), applied without a digest: Deployment nats, Service nats',
    'saying why';
  is_deeply ensured($k8s), [ 'Deployment/nats', 'Service/nats' ], 'one deploy';
  ok defined digest_on( $k8s, $_ => 'nats' ), $_.' carries a digest now' for qw( Deployment Service );

  for my $step ( 1, 2 ) {
    $k8s->clear_calls;
    is reconciled($comb)->phase, 'Running', 'step '.$step.' after: Running';
    is_deeply ensured($k8s), [], '... nothing applied';
  }
};

subtest 'one changed, one without a digest: both named' => sub {
  my ( $comb, $k8s ) = running();
  strip_digest( $k8s, Service => 'nats' );
  $comb->parts( [ with_image('img:2'), service('nats') ] );
  is ready( reconciled($comb) )->message,
    'applied 2 resource(s), rendered differently now: Deployment nats; applied without a digest: Service nats',
    'the message';
};

subtest 'a rolling restart between two steps triggers no deploy' => sub {
  my ( $comb, $k8s ) = running();
  my $digest = digest_on( $k8s, Deployment => 'nats' );
  ok defined $digest, 'the Deployment carries its digest';
  $comb->restart->get;
  my $at = stored( $k8s, Deployment => 'nats' )->{spec}{template}{metadata}{annotations}{$restarted_at};
  ok defined $at, 'restarted';
  is digest_on( $k8s, Deployment => 'nats' ), $digest, 'the digest stands';
  $k8s->clear_calls;

  # the rollout is through: all replicas ready again
  my $status = reconciled($comb);
  is $status->phase, 'Running', 'Running';
  is_deeply ensured($k8s), [], 'nothing applied';

  # a deploy that does come keeps the restart, and digests what was rendered
  $comb->parts( [ with_image('img:2'), service('nats') ] );
  is reconciled($comb)->phase, 'Pending', 'a changed manifest: deployed';
  my ( $sent ) = map { $_->[0] } $k8s->calls_of('ensure');
  is $sent->{spec}{template}{metadata}{annotations}{$restarted_at}, $at, 'the restart annotation is kept';
  my ( $fresh ) = comb( parts => [ with_image('img:2') ] );
  is $sent->{metadata}{annotations}{$key}, ( $fresh->_items( with_image('img:2') ) )[0]{digest},
    'the digest is that of the manifest without it';
  $k8s->clear_calls;
  is reconciled($comb)->phase, 'Running', 'the step after: Running';
  is_deeply ensured($k8s), [], 'nothing applied';
  is stored( $k8s, Deployment => 'nats' )->{spec}{template}{metadata}{annotations}{$restarted_at}, $at,
    'the restart stands';
};

# A Comb with a claim and a Job next to its Deployment, all healthy.
sub with_claim_and_job {
  my ( $comb, $k8s ) = comb( parts => [ claim( 'data', '1Gi' ), job( 'migrate', 'img' ), deployment('nats') ] );
  reconciled($comb);
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  set_status( $k8s, Job => 'migrate', { succeeded => 1, conditions => [ { type => 'Complete', status => 'True' } ] } );
  is reconciled($comb)->phase, 'Running', 'running';
  $k8s->clear_calls;
  return ( $comb, $k8s );
}

subtest 'a changed PersistentVolumeClaim or Job does not deploy every step' => sub {
  my ( $comb, $k8s ) = with_claim_and_job();
  my %before = map { ( $_->[0] => digest_on( $k8s, @$_ ) ) } [ PersistentVolumeClaim => 'data' ], [ Job => 'migrate' ];
  $comb->parts( [ claim( 'data', '2Gi' ), job( 'migrate', 'img:2' ), deployment('nats') ] );

  my $status = reconciled($comb);
  is $status->phase, 'Running', 'only what the client never replaces changed: Running';
  is_deeply ensured($k8s), [], 'nothing applied';

  $comb->parts( [ claim( 'data', '2Gi' ), job( 'migrate', 'img:2' ), with_image('img:2') ] );
  $status = reconciled($comb);
  is $status->phase, 'Pending', 'the Deployment changed too: Pending';
  is ready($status)->message, 'applied 3 resource(s), rendered differently now: Deployment nats',
    'the Deployment is why';
  is_deeply ensured($k8s), [ 'PersistentVolumeClaim/data', 'Job/migrate', 'Deployment/nats' ], 'all applied';
  is stored( $k8s, PersistentVolumeClaim => 'data' )->{spec}{resources}{requests}{storage}, '1Gi',
    'the client left the claim as it was';
  is stored( $k8s, Job => 'migrate' )->{spec}{template}{spec}{containers}[0]{image}, 'img',
    '... and the Job that succeeded';
  is digest_on( $k8s, PersistentVolumeClaim => 'data' ), $before{PersistentVolumeClaim}, 'the claim keeps its digest';
  is digest_on( $k8s, Job => 'migrate' ), $before{Job}, 'the Job too';

  for my $step ( 1, 2 ) {
    $k8s->clear_calls;
    is reconciled($comb)->phase, 'Running', 'step '.$step.' after: Running';
    is_deeply ensured($k8s), [], '... nothing applied';
  }
};

subtest 'a Job that runs keeps its digest as well' => sub {
  my ( $comb, $k8s ) = with_claim_and_job();
  set_status( $k8s, Job => 'migrate', { active => 1 } );
  $comb->parts( [ claim( 'data', '1Gi' ), job( 'migrate', 'img:2' ), deployment('nats') ] );
  my $status = reconciled($comb);
  is $status->phase, 'Pending', 'not healthy while it runs: Pending';
  like ready($status)->message, qr/not healthy yet \(Job migrate has not completed\)/, '... by its health, not its digest';
  is stored( $k8s, Job => 'migrate' )->{spec}{template}{spec}{containers}[0]{image}, 'img', 'left as it was';

  set_status( $k8s, Job => 'migrate', { succeeded => 1, conditions => [ { type => 'Complete', status => 'True' } ] } );
  $k8s->clear_calls;
  is reconciled($comb)->phase, 'Running', 'completed: Running';
  is_deeply ensured($k8s), [], 'nothing applied';
};

subtest 'a Job that failed is replaced, with the digest of the new one' => sub {
  my ( $comb, $k8s ) = with_claim_and_job();
  set_status( $k8s, Job => 'migrate', { failed => 7, conditions => [
    { type => 'Failed', status => 'True', reason => 'BackoffLimitExceeded', message => 'backoff limit' }
  ] } );
  $comb->parts( [ claim( 'data', '1Gi' ), job( 'migrate', 'img:2' ), deployment('nats') ] );
  my ( $rendered ) = grep { $_->{kind} eq 'Job' } $comb->_items( @{ $comb->parts } );

  my $status = reconciled($comb);
  is $status->phase, 'Pending', 'not healthy: deployed, Pending';
  like ready($status)->message, qr/not healthy yet \(Job migrate failed: backoff limit\)/, '... by its health';
  is stored( $k8s, Job => 'migrate' )->{spec}{template}{spec}{containers}[0]{image}, 'img:2', 'the client replaced it';
  is digest_on( $k8s, Job => 'migrate' ), $rendered->{digest}, 'it carries the digest of what is rendered now';
  ok !stored( $k8s, Job => 'migrate' )->{status}, 'and starts over';

  set_status( $k8s, Job => 'migrate', { succeeded => 1, conditions => [ { type => 'Complete', status => 'True' } ] } );
  $k8s->clear_calls;
  is reconciled($comb)->phase, 'Running', 'completed: Running';
  is_deeply ensured($k8s), [], 'nothing applied';
};

subtest 'the record and a digest differ: the digest decides, Pending' => sub {
  my ( $comb, $k8s ) = running();
  $comb->parts( [ with_image('img:2') ] );   # the Service dropped, the Deployment changed
  my $status = reconciled($comb);
  is $status->phase, 'Pending', 'Pending, not Running';
  like ready($status)->message, qr/\Aapplied 1 resource\(s\), rendered differently now: Deployment nats\z/, 'by the digest';
  is_deeply deleted($k8s), [ 'Service/nats' ], 'pruned as usual';
  is_deeply managed($status),
    [ { apiVersion => 'apps/v1', kind => 'Deployment', namespace => 'platform', name => 'nats' } ],
    'and recorded';
  $k8s->clear_calls;
  is reconciled($comb)->phase, 'Running', 'the step after: Running';
  is_deeply ensured($k8s), [], 'nothing applied';
};

subtest 'a resource a same-named Comb of another namespace applied last' => sub {
  # nats in getty and in dev, the layers in one cluster, both with a Service
  # in namespace shared: labelled, and digested, as the one that applied last
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my %comb = map { $_ => TestComb::Configurable->new(
    name      => 'nats',
    namespace => $_,
    k8s       => $k8s,
    parts     => [ deployment('nats'), service( 'nats-shared', namespace => 'shared' ) ]
  ) } qw( getty dev );
  for my $layer (qw( getty dev )) {
    reconciled( $comb{$layer} );
    set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 }, namespace => $layer );
  }
  is_deeply stored( $k8s, Service => 'nats-shared', 'shared' )->{metadata}{labels}, { comb_labels( 'nats', 'dev' ) },
    'dev applied it last';
  $k8s->clear_calls;

  for my $step ( 1, 2 ) {
    for my $layer (qw( getty dev )) {
      is reconciled( $comb{$layer} )->phase, 'Running', $layer.', step '.$step.': Running';
    }
  }
  is_deeply ensured($k8s), [], 'neither deploys it back and forth';
};

subtest 'a manifest that cannot be digested: Error' => sub {
  my $broken = deployment('nats');
  $broken->{spec}{template}{spec}{containers}[0]{command} = sub { 'ls' };
  my ( $comb, $k8s ) = comb( parts => [ $broken ] );
  my $status = reconciled($comb);
  is $status->phase, 'Error', 'Error';
  is ready($status)->reason, 'ManifestsFailed', 'ManifestsFailed';
  like ready($status)->message, qr/manifest Deployment nats cannot be digested: it holds a CODE reference/, 'saying why';
  is_deeply ensured($k8s), [], 'nothing applied';

  my $f = $comb->deploy;
  ok $f->is_failed, 'deploy: a failed Future, nothing thrown';
  is( ( $f->failure )[1], 'manifests', '... category manifests' );
};

subtest 'the upstream path applies the bridge every step, as before' => sub {
  my $answer = [];
  my ( $comb, $k8s ) = comb( offers => [ { name => 'client', port => 4222 } ], upstream => sub { @$answer } );
  @$answer = ( Static => ( endpoints => [ { name => 'client', port => 4222, cluster => 'nats.dev.example.com:4222' } ] ) );

  for my $step ( 1 .. 3 ) {
    $k8s->clear_calls;
    my $status = reconciled($comb);
    is $status->phase, 'Running', 'step '.$step.': Running';
    is ready($status)->reason, 'Borrowed', '... Borrowed';
    is_deeply ensured($k8s), [ 'Service/nats' ], '... the bridge applied';
  }
  my $bridge = stored( $k8s, Service => 'nats' );
  is $bridge->{spec}{type}, 'ExternalName', 'the bridge';
  like $bridge->{metadata}{annotations}{$key}, qr/\Asha256:[0-9a-f]{64}\z/, 'carries a digest like any resource deploy applies';

  # a bridge without one, or with another, changes nothing
  strip_digest( $k8s, Service => 'nats' );
  $k8s->clear_calls;
  my $status = reconciled($comb);
  is $status->phase, 'Running', 'a bridge applied without a digest: Running all the same';
  is_deeply ensured($k8s), [ 'Service/nats' ], 'applied as every step';
  is $comb->status->get->{phase}, 'Running', 'status: Running';

  @$answer = ();
  $k8s->clear_calls;
  $status = reconciled($comb);
  is $status->phase, 'Pending', 'back to local: deployed, Pending';
  like ready($status)->message, qr/\Aapplied 2 resource\(s\), not healthy yet/, 'as before';
};

done_testing;
