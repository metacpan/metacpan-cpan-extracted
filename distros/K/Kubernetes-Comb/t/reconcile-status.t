use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Kubernetes::Comb;
use Kubernetes::Comb::Client::Fake;
use Kubernetes::Comb::CRD::Comb;
use TestComb::Configurable;
use TestComb::Fixtures qw( deployment service set_status );

{
  package MyApp::CRD::Comb;
  use Moo;
  extends 'Kubernetes::Comb::CRD::Comb';
  sub api_version { 'comb.example.com/v1' }
}

our $NOW = '2026-09-27T10:00:00Z';
{
  no warnings 'redefine';
  *Kubernetes::Comb::_now = sub { $main::NOW };
}

my $conflict = 'Kubernetes API error (update_status Kubernetes::Comb::CRD::Comb): 409 Operation cannot be'
  .' fulfilled: the object has been modified';

# nats from a custom resource stored in the fake.
sub cr_comb {
  my ( %args ) = @_;
  my $crd_class = delete $args{crd_class} // 'Kubernetes::Comb::CRD::Comb';
  my $meta      = delete $args{metadata} // {};
  my $k8s = Kubernetes::Comb::Client::Fake->new( crd_class => $crd_class );
  $k8s->add( $crd_class->new(
    metadata => { name => 'nats', namespace => 'platform', %$meta },
    spec     => { class => 'TestComb::Configurable' }
  ) );
  my $comb = TestComb::Configurable->new(
    crd   => $k8s->object( Comb => 'nats', namespace => 'platform' ),
    k8s   => $k8s,
    parts => [ deployment('nats') ],
    %args
  );
  return ( $comb, $k8s );
}

sub stored_status {
  my ( $k8s ) = @_;
  return $k8s->object( Comb => 'nats', namespace => 'platform' )->status;
}

sub condition {
  my ( $status, $type ) = @_;
  my ( $condition ) = grep { $_->type eq $type } @{ $status->conditions // [] };
  return $condition;
}

sub since {
  my ( $status ) = @_;
  return { map { ( $_->type => $_->status.' '.$_->lastTransitionTime ) } @{ $status->conditions } };
}

subtest 'into the custom resource' => sub {
  my ( $comb, $k8s ) = cr_comb();
  my $before = $comb->crd;
  my $status = $comb->reconcile->get;

  my @writes = $k8s->calls_of('update_status');
  is scalar @writes, 1, 'one update_status';
  isa_ok $writes[0][0], 'Kubernetes::Comb::CRD::Comb', 'on the custom resource';
  is $writes[0][0]->status->phase, 'Pending', 'carrying the new status';
  is stored_status($k8s)->phase, 'Pending', 'the API server has it';

  isnt $comb->crd, $before, 'crd is replaced';
  is $comb->crd->metadata->resourceVersion, $k8s->object( Comb => 'nats', namespace => 'platform' )
    ->metadata->resourceVersion, '... by what the API server returned';
  is $comb->recorded_status->phase, 'Pending', 'recorded_status is the written one';
  is $status->phase, 'Pending', 'the Future has it too';
  ok !$before->status, 'the original object is untouched';
  ok !$k8s->calls_of('get'), 'no re-read needed';
};

subtest 'the next step starts from what was written' => sub {
  my ( $comb, $k8s ) = cr_comb();
  $comb->parts( [ deployment('nats'), service('nats') ] );
  $comb->reconcile->get;
  $comb->parts( [ deployment('nats') ] );
  $comb->reconcile->get;
  is_deeply [ map { $_->[0]->kind } $k8s->calls_of('delete') ], [ 'Service' ], 'prunes against the recorded managedResources';
};

subtest 'observedGeneration' => sub {
  my ( $comb ) = cr_comb( metadata => { generation => 7 } );
  is $comb->reconcile->get->observedGeneration, 7, 'from metadata.generation';
  ( $comb ) = cr_comb();
  ok !defined $comb->reconcile->get->observedGeneration, 'none without one';
};

subtest 'a conflict: re-read once, write again' => sub {
  my ( $comb, $k8s ) = cr_comb();
  # someone changed the spec meanwhile
  my $newer = $k8s->object( Comb => 'nats', namespace => 'platform' );
  $newer->spec->config( { size => 5 } );
  $k8s->add($newer);
  $k8s->fail_on( update_status => $conflict, times => 1 );

  my $status = $comb->reconcile->get;
  is $status->phase, 'Pending', 'the step went through';
  is scalar $k8s->calls_of('update_status'), 2, 'written twice';
  is_deeply [ $k8s->calls_of('get') ], [ [ '+Kubernetes::Comb::CRD::Comb', 'nats', namespace => 'platform' ] ],
    'after reading the custom resource again';
  is stored_status($k8s)->phase, 'Pending', 'the API server has the status';
  is_deeply $comb->crd->spec->config, { size => 5 }, 'crd is the fresh one';
  ok !condition( $status, 'StatusWritten' ), 'nothing to report';
};

subtest 'the write fails for good: kept in memory' => sub {
  my ( $comb, $k8s ) = cr_comb();
  $comb->parts( [ deployment('nats'), service('nats') ] );
  $k8s->fail_on( update_status => $conflict, times => 2 );

  my $f = $comb->reconcile;
  ok $f->is_done, 'still done';
  my $status = $f->get;
  is $status->phase, 'Pending', 'with the phase of the step';
  my $written = condition( $status, 'StatusWritten' );
  is $written->status, 'False', 'StatusWritten False';
  is $written->reason, 'WriteFailed', '... WriteFailed';
  like $written->message, qr/409 Operation cannot be fulfilled/, '... with the error';
  ok !stored_status($k8s), 'the API server has nothing';
  is $comb->recorded_status, $status, 'the Comb keeps it';

  $comb->parts( [ deployment('nats') ] );
  $status = $comb->reconcile->get;
  is_deeply [ map { $_->[0]->kind } $k8s->calls_of('delete') ], [ 'Service' ],
    'the next step prunes against what it kept';
  is stored_status($k8s)->phase, 'Pending', 'and writes';
  ok !condition( $status, 'StatusWritten' ), 'no StatusWritten once it worked';
};

subtest 'the re-read fails' => sub {
  my ( $comb, $k8s ) = cr_comb();
  $k8s->fail_on( update_status => $conflict, times => 1 );
  $k8s->fail_on( get => 'Kubernetes API error (get Comb): 404 not found', times => 1 );
  my $status = $comb->reconcile->get;
  is $status->phase, 'Pending', 'the step went through';
  like condition( $status, 'StatusWritten' )->message, qr/404 not found/, 'why the status was not written';
  is scalar $k8s->calls_of('update_status'), 1, 'no second write without a fresh read';
};

subtest 'a custom resource of another API group' => sub {
  my ( $comb, $k8s ) = cr_comb( crd_class => 'MyApp::CRD::Comb' );
  $k8s->fail_on( update_status => $conflict, times => 1 );
  $comb->reconcile->get;
  my @writes = $k8s->calls_of('update_status');
  isa_ok $writes[-1][0], 'MyApp::CRD::Comb', 'written as its own class';
  is( ( $k8s->calls_of('get') )[0][0], '+MyApp::CRD::Comb', 're-read as its own class' );
  isa_ok $comb->crd, 'MyApp::CRD::Comb', 'crd';
  is $comb->crd->status->phase, 'Pending', 'written';
};

subtest 'lastTransitionTime changes with the status only' => sub {
  my ( $comb, $k8s ) = cr_comb();
  local $NOW = '2026-09-27T10:00:00Z';
  my $status = $comb->reconcile->get;
  is_deeply since($status), {
    Ready             => 'False 2026-09-27T10:00:00Z',
    DependenciesReady => 'True 2026-09-27T10:00:00Z',
    ConfigReady       => 'True 2026-09-27T10:00:00Z'
  }, 'first step: now';

  $NOW = '2026-09-27T10:01:00Z';
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 0 } );
  $status = $comb->reconcile->get;
  is_deeply since($status), {
    Ready             => 'False 2026-09-27T10:00:00Z',
    DependenciesReady => 'True 2026-09-27T10:00:00Z',
    ConfigReady       => 'True 2026-09-27T10:00:00Z'
  }, 'same statuses: unchanged';
  like condition( $status, 'Ready' )->message, qr/0 of 1 ready/, 'the message still follows the step';

  $NOW = '2026-09-27T10:02:00Z';
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  $status = $comb->reconcile->get;
  is_deeply since($status), {
    Ready             => 'True 2026-09-27T10:02:00Z',
    DependenciesReady => 'True 2026-09-27T10:00:00Z',
    ConfigReady       => 'True 2026-09-27T10:00:00Z'
  }, 'Running: only Ready flipped';

  $NOW = '2026-09-27T10:03:00Z';
  $comb->missing( [ 'secret nats-auth' ] );
  $status = $comb->reconcile->get;
  is $status->phase, 'NeedsConfig', 'NeedsConfig';
  is_deeply since($status), {
    Ready             => 'False 2026-09-27T10:03:00Z',
    DependenciesReady => 'True 2026-09-27T10:00:00Z',
    ConfigReady       => 'False 2026-09-27T10:03:00Z'
  }, 'Ready and ConfigReady flipped';

  $NOW = '2026-09-27T10:04:00Z';
  $status = $comb->reconcile->get;
  is_deeply since($status), since( stored_status($k8s) ), 'what the API server holds';
  is condition( $status, 'ConfigReady' )->lastTransitionTime, '2026-09-27T10:03:00Z', 'still since the flip';
};

subtest 'without a custom resource' => sub {
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my $comb = TestComb::Configurable->new(
    name      => 'nats',
    namespace => 'platform',
    k8s       => $k8s,
    parts     => [ deployment('nats') ]
  );
  local $NOW = '2026-09-27T11:00:00Z';
  my $status = $comb->reconcile->get;
  ok !$k8s->calls_of($_), 'no '.$_ for qw( update_status patch_status get );
  is $comb->recorded_status, $status, 'kept in memory';
  ok !defined $status->observedGeneration, 'no generation';

  $NOW = '2026-09-27T11:05:00Z';
  is condition( $comb->reconcile->get, 'Ready' )->lastTransitionTime, '2026-09-27T11:00:00Z',
    'lastTransitionTime works in memory too';
};

done_testing;
