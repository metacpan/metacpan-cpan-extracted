use strict;
use warnings;
use Test::More;

# Integration test: a real cluster, SPEC section 12. Never run on its own
# initiative -- only with TEST_KUBERNETES_COMB_KUBECONFIG set by a human, and
# the cross-context part additionally with TEST_KUBERNETES_COMB_UPSTREAM_CONTEXT,
# which must name a context that reaches the SAME API server as the kubeconfig
# (another context of it, e.g. an alias with other credentials): a context of
# another API server ends Blocked, as SPEC section 7 says -- the peer publishes
# no external address.
# This file must never set either variable itself.

use Kubernetes::Comb::Client::Sync;
use Kubernetes::Comb::CRD::Comb;

unless ( $ENV{TEST_KUBERNETES_COMB_KUBECONFIG} ) {
  plan skip_all => 'set TEST_KUBERNETES_COMB_KUBECONFIG (a kubeconfig path) to run the integration suite'
    .' against a real cluster; unset, this is a unit run and nothing here touches a cluster';
}

# A tiny Comb: one Deployment (one small, already-cached image, no probes so
# it reports ready as soon as it runs) and a Service, offering one endpoint.
{
  package IntegrationTest::Comb;
  use Moo;
  extends 'Kubernetes::Comb';

  sub manifests {
    my ( $self ) = @_;
    return (
      {
        apiVersion => 'apps/v1',
        kind       => 'Deployment',
        metadata   => { name => $self->name },
        spec       => {
          replicas => 1,
          selector => { matchLabels => { app => $self->name } },
          template => {
            metadata => { labels => { app => $self->name } },
            spec     => {
              containers => [ {
                name    => 'main',
                image   => 'busybox:1.36',
                command => [ 'sleep', '3600' ]
              } ]
            }
          }
        }
      },
      {
        apiVersion => 'v1',
        kind       => 'Service',
        metadata   => { name => $self->name },
        spec       => { selector => { app => $self->name }, ports => [ { port => 80 } ] }
      }
    );
  }

  sub endpoints { ( { name => 'main', port => 80 } ) }
}

# Cleanup runs in an END block, in reverse order, no matter how the test
# below ends -- a failed assertion, a died Future ->get, or a plan skip_all
# reached after resources already exist.
my @cleanup;
END { while ( my $undo = pop @cleanup ) { eval { $undo->() } } }

sub unique_name {
  my ( $prefix ) = @_;
  return $prefix.'-'.time().'-'.$$.'-'.int( rand(1_000_000) );
}

# Retries transient failures right after creating a CustomResourceDefinition:
# the API server needs a moment to serve its Kind.
sub retrying {
  my ( $code, %args ) = @_;
  my $tries = $args{tries} // 15;
  my $delay = $args{delay} // 1;
  my ( @result, $error );
  for ( 1 .. $tries ) {
    @result = eval { $code->() };
    $error = $@;
    last unless $error;
    sleep $delay;
  }
  die $error if $error;
  return wantarray ? @result : $result[0];
}

# Reconciles up to $tries times, $delay seconds apart, until the phase is
# reached or the budget runs out; returns the last status either way.
sub reconcile_until {
  my ( $comb, $phase, %args ) = @_;
  my $tries = $args{tries} // 30;
  my $delay = $args{delay} // 2;
  my $status;
  for ( 1 .. $tries ) {
    $status = $comb->reconcile->get;
    last if $status->phase eq $phase;
    sleep $delay;
  }
  return $status;
}

sub live_json {
  my ( $k8s, $kind, $name, %args ) = @_;
  my $object = eval { $k8s->get( $kind, $name, %args )->get };
  return $object ? $object->TO_JSON : undef;
}

my $k8s = Kubernetes::Comb::Client::Sync->new( kubeconfig => $ENV{TEST_KUBERNETES_COMB_KUBECONFIG} );
my $ns   = unique_name('comb-it');
my $name = 'tiny';

subtest 'namespace and the CRD' => sub {
  $k8s->ensure( { apiVersion => 'v1', kind => 'Namespace', metadata => { name => $ns } } )->get;
  push @cleanup, sub { $k8s->delete( 'Namespace', $ns )->get };
  ok 1, 'namespace '.$ns.' created';

  my $crd_name = Kubernetes::Comb::CRD::Comb->to_crd->metadata->name;
  my $crd_existed = eval { $k8s->get( 'CustomResourceDefinition', $crd_name )->get; 1 };
  $k8s->ensure( Kubernetes::Comb::CRD::Comb->to_crd )->get;
  push @cleanup, sub { $k8s->delete( 'CustomResourceDefinition', $crd_name )->get } unless $crd_existed;
  ok 1, 'CustomResourceDefinition '.$crd_name.' installed'.( $crd_existed ? ' (already there)' : '' );
};

# The Comb, upstream resolved from a mutable answer so later steps can flip
# it between local and borrowing without rebuilding the object -- the same
# trick t/reconcile-borrow.t uses.
my @upstream_answer;
my $comb;

subtest 'the custom resource, reconciled to Running' => sub {
  my $cr = Kubernetes::Comb::CRD::Comb->new(
    metadata => { name => $name, namespace => $ns },
    spec     => { class => 'IntegrationTest::Comb' }
  );
  my $stored = retrying( sub { $k8s->ensure($cr)->get } );
  $comb = IntegrationTest::Comb->new( crd => $stored, k8s => $k8s, upstream => sub { @upstream_answer } );

  my $status = reconcile_until( $comb, 'Running' );
  is $status->phase, 'Running', 'Running within the bounded wait'
    or diag 'last phase: '.$status->phase.', message: '.( ( grep { $_->type eq 'Ready' } @{ $status->conditions } )[0]->message // '' );
  ok $comb->healthy->get, 'healthy agrees';
};

subtest 'status, logs, restart, stop' => sub {
  my $status = $comb->status->get;
  is $status->{phase}, 'Running', 'status: Running';

  my $logs = $comb->logs( lines => 20 );
  ok !$logs->is_failed, 'logs: not a failed Future'
    or diag $logs->failure;

  my @touched = $comb->restart->get;
  ok( ( grep { /\ADeployment\// } @touched ), 'restart touched the Deployment' );

  $comb->stop->get;
  my $stopped = live_json( $k8s, 'Deployment', $name, namespace => $ns );
  is $stopped->{spec}{replicas}, 0, 'stop: the Deployment is at 0 replicas on the API server';

  my $status_again = reconcile_until( $comb, 'Running' );
  is $status_again->phase, 'Running', 'a reconcile after stop deploys again';
};

subtest 'borrowing: the local ClusterIP Service becomes ExternalName' => sub {
  my $before = live_json( $k8s, 'Service', $name, namespace => $ns );
  ok $before->{spec}{clusterIP}, 'a ClusterIP was allocated for the local Service';

  @upstream_answer = ( Static => ( endpoints => [
    { name => 'main', port => 80, cluster => 'upstream.example.internal:80' }
  ] ) );
  my $status = reconcile_until( $comb, 'Running' );
  is $status->phase, 'Running', 'borrowing: Running (Upstream::Static reports Running by default)';

  my $service = live_json( $k8s, 'Service', $name, namespace => $ns );
  is $service->{spec}{type}, 'ExternalName', 'the Service is the bridge now';
  is $service->{spec}{externalName}, 'upstream.example.internal', 'pointing at the upstream';
  ok !( $service->{spec}{clusterIP} // '' ), 'the API server dropped the clusterIP -- k5 finding (d)';
  ok !$service->{spec}{selector}, 'and the selector';
  ok !live_json( $k8s, 'Deployment', $name, namespace => $ns ), 'the Deployment was pruned';
};

subtest 'back to local' => sub {
  @upstream_answer = ();
  my $status = reconcile_until( $comb, 'Running' );
  is $status->phase, 'Running', 'local again: Running';

  my $service = live_json( $k8s, 'Service', $name, namespace => $ns );
  # The API server defaults a Service's type to ClusterIP; what must be gone
  # is the bridge.
  is $service->{spec}{type}, 'ClusterIP', 'the Service is a plain ClusterIP Service again';
  ok !$service->{spec}{externalName}, 'and no externalName';
  ok $service->{spec}{clusterIP}, 'a fresh clusterIP was allocated';
  ok live_json( $k8s, 'Deployment', $name, namespace => $ns ), 'the Deployment is back';
};

# k15: stop and restart delete a Job with propagationPolicy Background, so the
# API server's garbage collector removes its Pods too. Asynchronous, hence the
# bounded wait. A Comb of its own, no custom resource needed.
{
  package IntegrationTest::JobComb;
  use Moo;
  extends 'Kubernetes::Comb';

  sub name { 'jobby' }

  sub manifests {
    my ( $self ) = @_;
    return ( {
      apiVersion => 'batch/v1',
      kind       => 'Job',
      metadata   => { name => $self->name },
      spec       => {
        template => {
          spec => {
            restartPolicy => 'Never',
            containers    => [ { name => 'main', image => 'busybox:1.36', command => [ 'sleep', '3600' ] } ]
          }
        }
      }
    } );
  }

  sub endpoints { () }
}

sub job_pods {
  my ( $comb ) = @_;
  my $list = $k8s->list( 'v1/Pod', namespace => $ns, labelSelector => $comb->label_selector )->get;
  return scalar @{ $list->items // [] };
}

# Polls $check up to $tries times, $delay seconds apart; true as soon as it is.
sub wait_for {
  my ( $check, %args ) = @_;
  my $tries = $args{tries} // 30;
  my $delay = $args{delay} // 2;
  for ( 1 .. $tries ) {
    return 1 if $check->();
    sleep $delay;
  }
  return 0;
}

for my $op (qw( stop restart )) {
  subtest 'a Job and its Pods are deleted together by '.$op => sub {
    my $jobber = IntegrationTest::JobComb->new( k8s => $k8s, namespace => $ns );
    $jobber->reconcile->get;
    ok live_json( $k8s, 'Job', 'jobby', namespace => $ns ), 'the Job exists';
    ok wait_for( sub { job_pods($jobber) > 0 } ), 'the Job has created a Pod within the bounded wait'
      or return;

    my @touched = $jobber->$op->get;
    ok( ( grep { $_ eq 'Job/jobby' } @touched ), $op.' touched the Job' );
    ok wait_for( sub { !live_json( $k8s, 'Job', 'jobby', namespace => $ns ) } ), 'the Job is gone';
    ok wait_for( sub { job_pods($jobber) == 0 } ), 'its Pods are gone too (garbage collected, not orphaned)'
      or diag job_pods($jobber).' Pod(s) left';
  };
}

# The layering path: a peer Comb reconciled for real in another kube
# context, borrowed from through Kubernetes::Comb::Upstream::K8s. Only with
# the second env var -- never set here.
SKIP: {
  skip 'set TEST_KUBERNETES_COMB_UPSTREAM_CONTEXT (a context reaching the SAME API server as the kubeconfig) to also exercise'
    .' Kubernetes::Comb::Upstream::K8s against a real peer', 1
    unless $ENV{TEST_KUBERNETES_COMB_UPSTREAM_CONTEXT};

  my $upstream_context = $ENV{TEST_KUBERNETES_COMB_UPSTREAM_CONTEXT};

  subtest 'Upstream::K8s: borrowing from a peer Comb in another context' => sub {
    my $peer_k8s = $k8s->for_context($upstream_context);
    my $peer_ns  = unique_name('comb-it-up');

    $peer_k8s->ensure( { apiVersion => 'v1', kind => 'Namespace', metadata => { name => $peer_ns } } )->get;
    push @cleanup, sub { $peer_k8s->delete( 'Namespace', $peer_ns )->get };

    my $crd_name = Kubernetes::Comb::CRD::Comb->to_crd->metadata->name;
    my $crd_existed = eval { $peer_k8s->get( 'CustomResourceDefinition', $crd_name )->get; 1 };
    $peer_k8s->ensure( Kubernetes::Comb::CRD::Comb->to_crd )->get;
    push @cleanup, sub { $peer_k8s->delete( 'CustomResourceDefinition', $crd_name )->get } unless $crd_existed;

    my $peer_cr = Kubernetes::Comb::CRD::Comb->new(
      metadata => { name => $name, namespace => $peer_ns },
      spec     => { class => 'IntegrationTest::Comb' }
    );
    my $peer_stored = retrying( sub { $peer_k8s->ensure($peer_cr)->get } );
    my $peer_comb = IntegrationTest::Comb->new( crd => $peer_stored, k8s => $peer_k8s );
    push @cleanup, sub { $peer_k8s->delete( 'Deployment', $name, namespace => $peer_ns )->get };

    my $peer_status = reconcile_until( $peer_comb, 'Running' );
    is $peer_status->phase, 'Running', 'the peer reconciled to Running on its own cluster';

    my $borrower_cr = Kubernetes::Comb::CRD::Comb->new(
      metadata => { name => $name.'-borrower', namespace => $ns },
      spec     => {
        class    => 'IntegrationTest::Comb',
        upstream => {
          class     => 'Kubernetes::Comb::Upstream::K8s',
          context   => $upstream_context,
          namespace => $peer_ns,
          name      => $name
        }
      }
    );
    my $borrower_stored = retrying( sub { $k8s->ensure($borrower_cr)->get } );
    my $borrower = IntegrationTest::Comb->new( crd => $borrower_stored, k8s => $k8s );
    push @cleanup, sub { $k8s->delete( 'Deployment', $name.'-borrower', namespace => $ns )->get };

    my $status = reconcile_until( $borrower, 'Running' );
    is $status->phase, 'Running', 'the borrower reads the peer across contexts and borrows its service'
      or diag 'last phase: '.$status->phase.', message: '.( ( grep { $_->type eq 'Ready' } @{ $status->conditions } )[0]->message // '' );
    ok $status->upstream, 'status.upstream recorded';
  };
}

done_testing;
