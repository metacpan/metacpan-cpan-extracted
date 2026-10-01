use strict;
use warnings;
use Test::More;

use lib 't/lib';
use IO::K8s;
use Kubernetes::Comb;
use Kubernetes::Comb::Client::Fake;
use TestComb::Fixtures qw( comb_labels pod set_status );

our @MANIFESTS;

{
  package TestComb::NATS;
  use Moo;
  extends 'Kubernetes::Comb';
  sub name      { 'nats' }
  sub manifests { @main::MANIFESTS }
}

sub deployment {
  my ( $name, %spec ) = @_;
  return {
    apiVersion => 'apps/v1',
    kind       => 'Deployment',
    metadata   => { name => $name },
    spec       => {
      selector => { matchLabels => { app => $name } },
      template => {
        metadata => { labels => { app => $name } },
        spec     => { containers => [ { name => 'main', image => 'img' } ] }
      },
      %spec
    }
  };
}

sub service   { { apiVersion => 'v1', kind => 'Service',   metadata => { name => $_[0] }, spec => { ports => [ { port => 4222 } ] } } }
sub configmap { { apiVersion => 'v1', kind => 'ConfigMap', metadata => { name => $_[0] }, data => { a => 'b' } } }

sub job {
  my ( $name ) = @_;
  return {
    apiVersion => 'batch/v1',
    kind       => 'Job',
    metadata   => { name => $name },
    spec       => { template => { spec => {
      restartPolicy => 'Never',
      containers    => [ { name => 'migrate', image => 'img' } ]
    } } }
  };
}

sub cronjob {
  my ( $name ) = @_;
  return {
    apiVersion => 'batch/v1',
    kind       => 'CronJob',
    metadata   => { name => $name },
    spec       => {
      schedule    => '0 3 * * *',
      jobTemplate => { spec => { template => { spec => {
        restartPolicy => 'OnFailure',
        containers    => [ { name => 'backup', image => 'img' } ]
      } } } }
    }
  };
}

# A Comb with @MANIFESTS deployed into a fresh fake.
sub deployed {
  my ( $k8s ) = ( Kubernetes::Comb::Client::Fake->new );
  my $comb = TestComb::NATS->new( k8s => $k8s, namespace => 'platform' );
  $comb->deploy->get;
  return ( $comb, $k8s );
}

sub status_of { $_[0]->status->get }

my %ready_container = ( name => 'main', ready => 1, state => { running => {} } );

subtest 'no manifests: running, nothing asked' => sub {
  local @MANIFESTS = ();
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my $status = status_of( TestComb::NATS->new( k8s => $k8s, namespace => 'platform' ) );
  is $status->{phase}, 'Running', 'phase';
  ok $status->{healthy}, 'healthy';
  is_deeply $k8s->calls, [], 'no request';
};

subtest 'nothing deployed yet' => sub {
  local @MANIFESTS = ( deployment('nats'), service('nats') );
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my $comb = TestComb::NATS->new( k8s => $k8s, namespace => 'platform' );
  my $status = status_of($comb);
  is $status->{phase}, 'NotDeployed', 'phase';
  ok !$status->{healthy}, 'not healthy';
  is $status->{reason}, 'NotDeployed', 'reason';
  is_deeply [ map { $_->[0] } $k8s->calls_of('list') ], [ 'apps/v1/Deployment', 'v1/Service' ],
    'one list per resource';
  is_deeply +{ @{ ( $k8s->calls_of('list') )[0] }[ 1 .. 4 ] },
    { namespace => 'platform', labelSelector => 'comb.internal/comb=nats' },
    'by the name label, in the namespace: a same-named Comb elsewhere may have applied a shared one last';
  ok !grep( { $_->[0] eq 'v1/Pod' } $k8s->calls_of('list') ), 'no pods asked for';
};

subtest 'no workloads: healthy once the resources exist' => sub {
  local @MANIFESTS = ( service('nats'), configmap('nats-conf') );
  my ( $comb, $k8s ) = deployed();
  my $status = status_of($comb);
  is $status->{phase}, 'Running', 'all there: running';
  ok $status->{healthy}, 'healthy';
  ok !exists $status->{reason}, 'no reason';

  $k8s->delete( 'ConfigMap', 'nats-conf', namespace => 'platform' )->get;
  $status = status_of($comb);
  is $status->{phase}, 'Pending', 'one missing: pending';
  is $status->{reason}, 'ResourcesMissing', 'reason';
  like $status->{message}, qr/ConfigMap nats-conf is missing/, 'names it';
  ok !$status->{healthy}, 'not healthy';
};

subtest 'manifests as IO::K8s objects' => sub {
  my $io = IO::K8s->new;
  local @MANIFESTS = ( $io->new_object( Service => service('nats') ), $io->new_object( ConfigMap => configmap('nats-conf') ) );
  my ( $comb, $k8s ) = deployed();
  $k8s->clear_calls;
  is status_of($comb)->{phase}, 'Running', 'found';
  is_deeply [ map { $_->[0] } $k8s->calls_of('list') ],
    [ '+IO::K8s::Api::Core::V1::ConfigMap', '+IO::K8s::Api::Core::V1::Service' ], 'listed by their class';
  $k8s->delete( 'Service', 'nats', namespace => 'platform' )->get;
  like status_of($comb)->{message}, qr/Service nats is missing/, 'missing';
};

subtest 'a resource without the Comb label counts as missing' => sub {
  local @MANIFESTS = ( configmap('nats-conf') );
  my $k8s = Kubernetes::Comb::Client::Fake->new( objects => [ { %{ configmap('nats-conf') },
    metadata => { name => 'nats-conf', namespace => 'platform' } } ] );
  my $status = status_of( TestComb::NATS->new( k8s => $k8s, namespace => 'platform' ) );
  is $status->{phase}, 'NotDeployed', 'someone else\'s object is not ours';
};

subtest 'running' => sub {
  local @MANIFESTS = ( deployment( 'nats', replicas => 2 ), service('nats') );
  my ( $comb, $k8s ) = deployed();
  set_status( $k8s, Deployment => 'nats', { replicas => 2, readyReplicas => 2 } );
  $k8s->add(
    pod( 'nats-a', owner => 'ReplicaSet', containers => [ \%ready_container ] ),
    pod( 'nats-b', owner => 'ReplicaSet', containers => [ { %ready_container, restartCount => 1 } ] )
  );
  my $status = status_of($comb);
  is $status->{phase}, 'Running', 'phase';
  ok $status->{healthy}, 'healthy';
  ok $comb->healthy->get, 'healthy() agrees';
  is_deeply [ map { $_->{name} } @{ $status->{pods} } ], [qw( nats-a nats-b )], 'pods listed';
  is $status->{pods}[1]{restarts}, 1, 'restarts counted';
  ok $status->{pods}[0]{ready}, 'ready';
  is_deeply +{ @{ ( grep { $_->[0] eq 'v1/Pod' } $k8s->calls_of('list') )[0] }[ 1 .. 4 ] },
    { namespace => 'platform', labelSelector => 'comb.internal/comb=nats,comb.internal/comb-namespace=platform' },
    'pods by the Comb labels';
};

subtest 'readiness means containers ready, not phase Running' => sub {
  local @MANIFESTS = ( deployment('nats') );
  my ( $comb, $k8s ) = deployed();
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  $k8s->add( pod( 'nats-a', owner => 'ReplicaSet', containers => [
    { name => 'main', ready => 0, state => { running => {} } }
  ] ) );
  my $status = status_of($comb);
  is $status->{phase}, 'Pending', 'running but not ready: pending';
  is $status->{reason}, 'ContainersNotReady', 'reason';
  ok !$status->{pods}[0]{ready}, 'the pod is not ready';
  ok !$comb->healthy->get, 'not healthy';
};

subtest 'crash loop: error with reason and restart count' => sub {
  local @MANIFESTS = ( deployment('nats') );
  my ( $comb, $k8s ) = deployed();
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 0 } );
  $k8s->add( pod( 'nats-a', owner => 'ReplicaSet', containers => [ {
    name         => 'main',
    ready        => 0,
    restartCount => 7,
    state        => { waiting => { reason => 'CrashLoopBackOff', message => 'back-off 5m0s restarting failed container' } }
  } ] ) );
  my $status = status_of($comb);
  is $status->{phase}, 'Error', 'phase';
  is $status->{reason}, 'CrashLoopBackOff', 'reason';
  like $status->{message}, qr/Pod nats-a: CrashLoopBackOff: back-off 5m0s restarting failed container \(7 restarts\)/,
    'message with the restart count';
  like $status->{message}, qr/Deployment nats: 0 of 1 ready/, 'and the workload';
  is $status->{pods}[0]{reason}, 'CrashLoopBackOff', 'on the pod too';
  is $status->{pods}[0]{restarts}, 7, 'restarts';
};

subtest 'image pull failure is an error, container creation is pending' => sub {
  local @MANIFESTS = ( deployment('nats') );
  my ( $comb, $k8s ) = deployed();
  $k8s->add( pod( 'nats-a', owner => 'ReplicaSet', phase => 'Pending', containers => [ {
    name => 'main', state => { waiting => { reason => 'ImagePullBackOff', message => 'Back-off pulling image "nats:nope"' } }
  } ] ) );
  is status_of($comb)->{phase}, 'Error', 'ImagePullBackOff';

  $k8s->add( pod( 'nats-a', owner => 'ReplicaSet', phase => 'Pending', containers => [ {
    name => 'main', state => { waiting => { reason => 'ContainerCreating' } }
  } ] ) );
  my $status = status_of($comb);
  is $status->{phase}, 'Pending', 'ContainerCreating';
  is $status->{reason}, 'ContainerCreating', 'the waiting reason first, before the workload';
};

subtest 'terminated containers' => sub {
  local @MANIFESTS = ( deployment('nats') );
  my ( $comb, $k8s ) = deployed();
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  $k8s->add( pod( 'nats-a', owner => 'ReplicaSet', containers => [ {
    name => 'main', restartCount => 2, state => { terminated => { reason => 'OOMKilled', exitCode => 137 } }
  } ] ) );
  my $status = status_of($comb);
  is $status->{phase}, 'Error', 'a container that died';
  is $status->{reason}, 'OOMKilled', 'terminated reason';
  like $status->{message}, qr/OOMKilled: exit code 137 \(2 restarts\)/, 'exit code';

  $k8s->add( pod( 'nats-a', owner => 'ReplicaSet', phase => 'Pending',
    init       => [ { name => 'init', state => { terminated => { reason => 'Completed', exitCode => 0 } } } ],
    containers => [ { name => 'main', state => { waiting => { reason => 'PodInitializing' } } } ]
  ) );
  $status = status_of($comb);
  is $status->{reason}, 'PodInitializing', 'a completed init container is no problem';
  is $status->{phase}, 'Pending', 'pending';

  $k8s->add( pod( 'nats-a', owner => 'ReplicaSet', phase => 'Pending',
    init       => [ { name => 'init', restartCount => 3, state => { waiting => { reason => 'CrashLoopBackOff' } } } ],
    containers => [ { name => 'main', state => { waiting => { reason => 'PodInitializing' } } } ]
  ) );
  $status = status_of($comb);
  is $status->{reason}, 'CrashLoopBackOff', 'a crashing init container is';
  is $status->{phase}, 'Error', 'an error';
};

subtest 'scheduling failure' => sub {
  local @MANIFESTS = ( deployment('nats') );
  my ( $comb, $k8s ) = deployed();
  $k8s->add( pod( 'nats-a', owner => 'ReplicaSet', phase => 'Pending', containers => [],
    conditions => [ {
      type    => 'PodScheduled',
      status  => 'False',
      reason  => 'Unschedulable',
      message => '0/3 nodes are available: 3 Insufficient memory.'
    } ]
  ) );
  my $status = status_of($comb);
  is $status->{phase}, 'Pending', 'pending, it may still fit';
  is $status->{reason}, 'Unschedulable', 'reason from PodScheduled=False';
  like $status->{message}, qr/Pod nats-a: Unschedulable: 0\/3 nodes are available: 3 Insufficient memory\./, 'message';
};

subtest 'replicas the pods do not show yet' => sub {
  local @MANIFESTS = ( deployment( 'nats', replicas => 3 ) );
  my ( $comb, $k8s ) = deployed();
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  $k8s->add( pod( 'nats-a', owner => 'ReplicaSet', containers => [ \%ready_container ] ) );
  my $status = status_of($comb);
  is $status->{phase}, 'Pending', 'one of three ready';
  is $status->{reason}, 'ReplicasNotReady', 'reason';
  like $status->{message}, qr/Deployment nats: 1 of 3 ready/, 'message';
};

subtest 'jobs: succeeded pods are fine, the job decides' => sub {
  local @MANIFESTS = ( job('migrate'), service('nats') );
  my ( $comb, $k8s ) = deployed();
  $k8s->add( pod( 'migrate-a', owner => 'Job', phase => 'Succeeded', containers => [
    { name => 'migrate', state => { terminated => { reason => 'Completed', exitCode => 0 } } }
  ] ) );
  set_status( $k8s, Job => 'migrate', { succeeded => 1, conditions => [ { type => 'Complete', status => 'True' } ] } );
  my $status = status_of($comb);
  is $status->{phase}, 'Running', 'a completed job and its succeeded pod: running';
  ok $status->{healthy}, 'healthy';
  is $status->{pods}[0]{phase}, 'Succeeded', 'the pod is still listed';

  set_status( $k8s, Job => 'migrate', { active => 1 } );
  $status = status_of($comb);
  is $status->{phase}, 'Pending', 'a job still running: pending';
  is $status->{reason}, 'JobNotComplete', 'reason';

  set_status( $k8s, Job => 'migrate', { failed => 7, conditions => [
    { type => 'Failed', status => 'True', reason => 'BackoffLimitExceeded', message => 'Job has reached the specified backoff limit' }
  ] } );
  $k8s->add( pod( 'migrate-b', owner => 'Job', phase => 'Failed', containers => [
    { name => 'migrate', state => { terminated => { reason => 'Error', exitCode => 1 } } }
  ] ) );
  $status = status_of($comb);
  is $status->{phase}, 'Error', 'a failed job: error';
  is $status->{reason}, 'BackoffLimitExceeded', 'reason from the job';
  like $status->{message}, qr/Job migrate failed: Job has reached the specified backoff limit/, 'message';
  is $status->{pods}[1]{reason}, 'Error', 'the failed pod shows its reason';
  unlike $status->{message}, qr/Pod migrate-b/, 'but the job speaks for it';
};

subtest 'failed pods: a controller\'s are left to it, a bare one is an error' => sub {
  local @MANIFESTS = ( deployment('nats') );
  my ( $comb, $k8s ) = deployed();
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  $k8s->add(
    pod( 'nats-a', owner => 'ReplicaSet', containers => [ \%ready_container ] ),
    pod( 'nats-old', owner => 'ReplicaSet', phase => 'Failed', reason => 'Evicted',
      message => 'The node was low on resource: memory.', containers => [] )
  );
  my $status = status_of($comb);
  is $status->{phase}, 'Running', 'an evicted pod of a Deployment does not count';
  is $status->{pods}[1]{reason}, 'Evicted', 'it is listed with its reason';

  local @MANIFESTS = ( { apiVersion => 'v1', kind => 'Pod', metadata => { name => 'solo' },
    spec => { containers => [ { name => 'main', image => 'img' } ] } } );
  ( $comb, $k8s ) = deployed();
  $k8s->add( pod( 'solo', phase => 'Failed', containers => [
    { name => 'main', state => { terminated => { reason => 'Error', exitCode => 2, message => 'boom' } } }
  ] ) );
  $status = status_of($comb);
  is $status->{phase}, 'Error', 'a failed bare pod is an error';
  like $status->{message}, qr/Pod solo: Error: exit code 2: boom/, 'with its exit code';
};

subtest 'daemon sets' => sub {
  local @MANIFESTS = ( {
    apiVersion => 'apps/v1',
    kind       => 'DaemonSet',
    metadata   => { name => 'agent' },
    spec       => {
      selector => { matchLabels => { app => 'agent' } },
      template => { metadata => { labels => { app => 'agent' } }, spec => { containers => [ { name => 'a', image => 'img' } ] } }
    }
  } );
  my ( $comb, $k8s ) = deployed();
  set_status( $k8s, DaemonSet => 'agent', { desiredNumberScheduled => 3, numberReady => 2,
    currentNumberScheduled => 3, numberMisscheduled => 0 } );
  my $status = status_of($comb);
  is $status->{phase}, 'Pending', 'two of three nodes';
  like $status->{message}, qr/DaemonSet agent: 2 of 3 ready/, 'message';
};

subtest 'stopped' => sub {
  local @MANIFESTS = ( deployment('nats'), cronjob('backup'), job('migrate'), service('nats') );
  my ( $comb, $k8s ) = deployed();
  $comb->stop->get;
  my $status = status_of($comb);
  is $status->{phase}, 'Stopped', 'after stop';
  ok !$status->{healthy}, 'not healthy';
  is $status->{reason}, 'Stopped', 'reason';

  $k8s->patch( 'CronJob', 'backup', namespace => 'platform', patch => { spec => { suspend => \0 } } )->get;
  isnt status_of($comb)->{phase}, 'Stopped', 'a CronJob running again';
};

sub daemonset {
  my ( $name ) = @_;
  return {
    apiVersion => 'apps/v1',
    kind       => 'DaemonSet',
    metadata   => { name => $name },
    spec       => {
      selector => { matchLabels => { app => $name } },
      template => { metadata => { labels => { app => $name } }, spec => { containers => [ { name => 'a', image => 'img' } ] } }
    }
  };
}

subtest 'stopped: what stop leaves running does not count' => sub {
  local @MANIFESTS = ( deployment('nats'), daemonset('agent') );
  my ( $comb, $k8s ) = deployed();
  set_status( $k8s, Deployment => 'nats', { replicas => 1, readyReplicas => 1 } );
  set_status( $k8s, DaemonSet => 'agent', { desiredNumberScheduled => 1, numberReady => 1,
    currentNumberScheduled => 1, numberMisscheduled => 0 } );
  is status_of($comb)->{phase}, 'Running', 'running';

  $comb->stop->get;
  set_status( $k8s, Deployment => 'nats', { replicas => 0 } );
  my $status = status_of($comb);
  is $status->{phase}, 'Stopped', 'the DaemonSet stop leaves alone: still Stopped';
  ok !$status->{healthy}, 'not healthy';

  local @MANIFESTS = ( deployment('nats'), { apiVersion => 'apps/v1', kind => 'ReplicaSet', metadata => { name => 'nats-rs' },
    spec => { selector => { matchLabels => { app => 'rs' } }, template => { metadata => { labels => { app => 'rs' } },
      spec => { containers => [ { name => 'main', image => 'img' } ] } } } } );
  ( $comb, $k8s ) = deployed();
  set_status( $k8s, ReplicaSet => 'nats-rs', { replicas => 1, readyReplicas => 1 } );
  $comb->stop->get;
  is status_of($comb)->{phase}, 'Stopped', 'nor does a ReplicaSet';
};

subtest 'scaled below the manifest: short of replicas' => sub {
  local @MANIFESTS = ( deployment('nats'), deployment('nats-web') );
  my ( $comb, $k8s ) = deployed();
  set_status( $k8s, Deployment => $_, { replicas => 1, readyReplicas => 1 } ) for qw( nats nats-web );
  is status_of($comb)->{phase}, 'Running', 'both ready';

  # kubectl scale --replicas=0 deployment/nats-web
  $k8s->patch( 'Deployment', 'nats-web', namespace => 'platform', patch => { spec => { replicas => 0 } } )->get;
  set_status( $k8s, Deployment => 'nats-web', { replicas => 0 } );
  my $status = status_of($comb);
  is $status->{phase}, 'Pending', 'one scaled to 0: Pending, not Running';
  ok !$status->{healthy}, 'not healthy';
  is $status->{reason}, 'ReplicasNotReady', 'reason';
  like $status->{message}, qr/Deployment nats-web: 0 of 1 ready \(scaled to 0\)/,
    'measured against the manifest (no replicas: 1, what deploy sets)';

  local @MANIFESTS = ( deployment( 'nats', replicas => 3 ) );
  ( $comb, $k8s ) = deployed();
  $k8s->patch( 'Deployment', 'nats', namespace => 'platform', patch => { spec => { replicas => 1 } } )->get;
  set_status( $k8s, Deployment => 'nats', { replicas => 1, readyReplicas => 1 } );
  like status_of($comb)->{message}, qr/Deployment nats: 1 of 3 ready \(scaled to 1\)/, 'scaled to 1 of 3';
};

subtest 'scaled beyond the manifest: the scale counts' => sub {
  local @MANIFESTS = ( deployment( 'nats', replicas => 2 ) );
  my ( $comb, $k8s ) = deployed();
  # an autoscaler at work
  $k8s->patch( 'Deployment', 'nats', namespace => 'platform', patch => { spec => { replicas => 4 } } )->get;
  set_status( $k8s, Deployment => 'nats', { replicas => 4, readyReplicas => 3 } );
  my $status = status_of($comb);
  is $status->{phase}, 'Pending', 'three of four: Pending';
  like $status->{message}, qr/Deployment nats: 3 of 4 ready\z/, 'against the scale';
  set_status( $k8s, Deployment => 'nats', { replicas => 4, readyReplicas => 4 } );
  is status_of($comb)->{phase}, 'Running', 'all four: Running';
};

subtest 'at rest as the manifest says: Running, not Stopped' => sub {
  local @MANIFESTS = ( deployment( 'nats', replicas => 0 ),
    { %{ cronjob('backup') }, spec => { %{ cronjob('backup')->{spec} }, suspend => \1 } } );
  my ( $comb, $k8s ) = deployed();
  my $status = status_of($comb);
  is $status->{phase}, 'Running', 'replicas 0 and suspended by the manifest: Running';
  ok $status->{healthy}, 'healthy';

  $comb->stop->get;
  is status_of($comb)->{phase}, 'Running', 'stop changes nothing then';

  local @MANIFESTS = ( deployment( 'nats', replicas => 0 ), deployment('nats-web') );
  ( $comb, $k8s ) = deployed();
  $comb->stop->get;
  is status_of($comb)->{phase}, 'Stopped', 'one stopped against its manifest: Stopped';
};

subtest 'errors fail the Future' => sub {
  local @MANIFESTS = ( deployment('nats') );
  my ( $comb, $k8s ) = deployed();
  $k8s->fail_on( list => 'Kubernetes API error (list Deployment): 403 forbidden' );
  my $f = $comb->status;
  ok $f->is_failed, 'a failed list';
  like $f->failure, qr/403 forbidden/, 'passes the error on';
  ok $comb->healthy->is_failed, 'healthy fails too';

  no warnings 'once';
  local *TestComb::NATS::manifests = sub { die "broken\n" };
  is $comb->status->failure, "broken\n", 'manifests dying';
};

done_testing;
