use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Kubernetes::Comb;
use Kubernetes::Comb::Client::Fake;
use Kubernetes::Comb::CRD::CombStatus;
use TestComb::Configurable;
use TestComb::Fixtures qw( comb_labels deployment service );

my %labels = comb_labels('nats');
my %deployment_nats = ( apiVersion => 'apps/v1', kind => 'Deployment', namespace => 'platform', name => 'nats' );
my %service_old     = ( apiVersion => 'v1', kind => 'Service', namespace => 'platform', name => 'old' );

sub comb {
  my ( %args ) = @_;
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my $comb = TestComb::Configurable->new(
    name      => 'nats',
    namespace => 'platform',
    k8s       => $k8s,
    parts     => [ deployment('nats') ],
    %args
  );
  return ( $comb, $k8s );
}

sub record {
  my ( $comb, @resources ) = @_;
  $comb->_memory_status( Kubernetes::Comb::CRD::CombStatus->new( phase => 'Pending', managedResources => \@resources ) );
}

subtest 'rendered_resources: labelled objects, nothing applied' => sub {
  my ( $comb, $k8s ) = comb();
  my @objects = $comb->rendered_resources->get;
  is scalar @objects, 1, 'one object';
  is $objects[0]{kind}, 'Deployment', 'the Deployment';
  is $objects[0]{metadata}{labels}{$_}, $labels{$_}, 'label '.$_ for sort keys %labels;
  is $objects[0]{metadata}{namespace}, 'platform', 'namespace set';
  ok $objects[0]{metadata}{annotations}{ $comb->applied_digest_annotation }, 'digest annotation';
  is_deeply [ $k8s->calls_of('ensure') ], [], 'nothing applied';
};

subtest 'rendered_resources: a broken manifest fails the Future' => sub {
  my ( $comb ) = comb( parts => sub { die "boom\n" } );
  my $f = $comb->rendered_resources;
  ok $f->is_failed, 'failed';
  like( ( $f->failure )[0], qr/boom/, 'with the reason' );
};

subtest 'plan: a fresh Comb creates, an orphan is deleted' => sub {
  my ( $comb, $k8s ) = comb();
  record( $comb, {%deployment_nats}, {%service_old} );
  $k8s->add( service( 'old', namespace => 'platform', labels => {%labels} ) );
  my $plan = $comb->plan->get;
  is_deeply $plan, { create => [ {%deployment_nats} ], update => [], delete => [ {%service_old} ] }, 'plan';
  is_deeply [ $k8s->calls_of('ensure') ], [], 'nothing applied';
  is_deeply [ $k8s->calls_of('delete') ], [], 'nothing deleted';
};

subtest 'plan agrees with reconcile: empty afterwards, the pruned one was in delete' => sub {
  my ( $comb, $k8s ) = comb();
  record( $comb, {%deployment_nats}, {%service_old} );
  $k8s->add( service( 'old', namespace => 'platform', labels => {%labels} ) );
  my $plan = $comb->plan->get;
  $comb->reconcile->get;
  is_deeply [ map { $_->[0]->kind.'/'.$_->[0]->metadata->name } $k8s->calls_of('delete') ], ['Service/old'],
    'reconcile pruned what plan listed under delete';
  is_deeply $plan->{delete}, [ {%service_old} ], 'plan had it';
  is_deeply $comb->plan->get, { create => [], update => [], delete => [] }, 'plan is empty after reconcile';
};

subtest 'plan: update is what reconcile sees as changed' => sub {
  my ( $comb, $k8s ) = comb();
  $comb->reconcile->get;
  is_deeply $comb->plan->get, { create => [], update => [], delete => [] }, 'in sync';
  my $changed = deployment('nats');
  $changed->{spec}{replicas} = 3;
  $comb->parts( [$changed] );
  is_deeply $comb->plan->get, { create => [], update => [ {%deployment_nats} ], delete => [] },
    'a manifest rendered differently now is an update';
  $comb->reconcile->get;
  is_deeply $comb->plan->get, { create => [], update => [], delete => [] }, 'empty after reconcile';
};

subtest 'plan: cluster-scoped orphans are not pruned, so not listed' => sub {
  my ( $comb, $k8s ) = comb();
  record( $comb, {%deployment_nats}, { apiVersion => 'v1', kind => 'Namespace', name => 'extra' } );
  $comb->reconcile->get;
  is_deeply $comb->plan->get->{delete}, [], 'reconcile leaves it in place, plan does not list it';
};

subtest 'plan: failures are a failed Future' => sub {
  my ( $comb ) = comb( parts => sub { die "boom\n" } );
  my $f = $comb->plan;
  ok $f->is_failed, 'failed';
  like( ( $f->failure )[0], qr/boom/, 'with the reason' );
};

done_testing;
