use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Kubernetes::Comb::Client::Fake;
use Kubernetes::Comb::Upstream::K8s;
use TestComb::Configurable;
use TestComb::Fixtures qw( comb_cr );

my $class = 'Kubernetes::Comb::Upstream::K8s';
my $here  = 'https://here.example:6443';

# The peer Comb CR as the other context holds it: nats in platform, with the
# status its own reconcile wrote.
sub peer {
  my ( %status ) = @_;
  my $name      = delete $status{name}      // 'nats';
  my $namespace = delete $status{namespace} // 'platform';
  return {
    %{ comb_cr( name => $name, namespace => $namespace, class => 'TestComb::Configurable' )->TO_JSON },
    ( %status ? ( status => \%status ) : () )
  };
}

my @published = (
  { name => 'client',  protocol => 'tcp', port => 4222, cluster => 'nats.platform.svc:4222', external => 'nats.dev.example.com:4222' },
  { name => 'monitor', protocol => 'tcp', port => 8222, cluster => 'nats.platform.svc:8222' }
);

# nats in namespace getty, whose client knows the context dev.
sub setup {
  my ( %args ) = @_;
  my $dev = Kubernetes::Comb::Client::Fake->new(
    server_url => $args{server_url} // 'https://dev.example:6443',
    objects    => $args{objects} // [ peer( phase => 'Running', endpoints => [@published] ) ]
  );
  my $k8s = Kubernetes::Comb::Client::Fake->new( server_url => $here, contexts => { dev => $dev } );
  my $comb = TestComb::Configurable->new( name => 'nats', namespace => $args{namespace} // 'getty', k8s => $k8s );
  return ( $comb, $dev );
}

sub endpoints_of {
  my ( $upstream, $comb ) = @_;
  return [ map { $_->to_crd->TO_JSON } @{ $upstream->endpoints($comb)->get } ];
}

subtest 'another API server: the external addresses' => sub {
  my ( $comb ) = setup();
  my $upstream = $class->new( context => 'dev', namespace => 'platform' );
  ok $upstream->DOES('Kubernetes::Comb::Role::Upstream'), 'does the role';

  my $f = $upstream->status($comb);
  isa_ok $f, 'Future';
  is_deeply $f->get, {
    reachable => 1,
    phase     => 'Running',
    context   => 'dev',
    via       => [ 'dev' ],
    message   => 'no address reachable from here for endpoint(s) monitor: context dev is another API server,'
      .' and Comb platform/nats in context dev publishes no external address'
  }, 'status: reachable, the peer\'s phase, the endpoint it cannot reach';
  is_deeply endpoints_of( $upstream, $comb ), [
    { name => 'client', protocol => 'tcp', port => 4222, cluster => 'nats.dev.example.com:4222', external => 'nats.dev.example.com:4222' }
  ], 'endpoints: the external address to use from here, the one without none left out';
};

subtest 'the same API server: the cluster addresses' => sub {
  my ( $comb ) = setup( server_url => $here );
  my $upstream = $class->new( context => 'dev', namespace => 'platform' );
  my $status = $upstream->status($comb)->get;
  ok $status->{reachable}, 'reachable';
  ok !exists $status->{message}, 'every endpoint has an address';
  is_deeply endpoints_of( $upstream, $comb ), [
    { name => 'client',  protocol => 'tcp', port => 4222, cluster => 'nats.platform.svc:4222', external => 'nats.dev.example.com:4222' },
    { name => 'monitor', protocol => 'tcp', port => 8222, cluster => 'nats.platform.svc:8222' }
  ], 'the peer\'s cluster addresses';
};

subtest 'the same API server, only an external address' => sub {
  my ( $comb ) = setup( server_url => $here, objects => [ peer( phase => 'Running', endpoints => [
    { name => 'client', port => 4222, external => 'nats.dev.example.com:4222' }
  ] ) ] );
  is_deeply endpoints_of( $class->new( context => 'dev', namespace => 'platform' ), $comb ), [
    { name => 'client', protocol => 'tcp', port => 4222, cluster => 'nats.dev.example.com:4222', external => 'nats.dev.example.com:4222' }
  ], 'is reachable from inside too';
};

subtest 'via: this context, then the peer\'s layers' => sub {
  my ( $comb ) = setup( objects => [ peer( phase => 'Running', endpoints => [@published],
    upstream => { class => $class, context => 'prod', reachable => \1, phase => 'Running', via => [ 'prod', 'vendor' ] } ) ] );
  is_deeply $class->new( context => 'dev', namespace => 'platform' )->status($comb)->get->{via},
    [ 'dev', 'prod', 'vendor' ], 'via';
};

subtest 'namespace and name default to the Comb\'s own' => sub {
  my ( $comb, $dev ) = setup( namespace => 'platform' );
  my $upstream = $class->new( context => 'dev' );
  ok $upstream->status($comb)->get->{reachable}, 'found';
  is_deeply [ $dev->calls_of('get') ], [ [ '+Kubernetes::Comb::CRD::Comb', 'nats', namespace => 'platform' ] ],
    'read as the crd_class, read-only, by the Comb\'s namespace and name';

  ( $comb, $dev ) = setup( objects => [ peer( name => 'queue', namespace => 'shared', phase => 'Running' ) ] );
  ok $class->new( context => 'dev', namespace => 'shared', name => 'queue' )->status($comb)->get->{reachable},
    'others when given';
  is_deeply [ $dev->calls_of('get') ], [ [ '+Kubernetes::Comb::CRD::Comb', 'queue', namespace => 'shared' ] ], '... read so';
};

subtest 'a peer that has not reconciled yet' => sub {
  my ( $comb ) = setup( objects => [ peer() ] );
  my $upstream = $class->new( context => 'dev', namespace => 'platform' );
  is_deeply $upstream->status($comb)->get, { reachable => 1, context => 'dev', via => [ 'dev' ] },
    'reachable, no phase';
  is_deeply endpoints_of( $upstream, $comb ), [], 'no endpoints';
};

subtest 'unreachable, never an exception' => sub {
  my $unreachable = sub {
    my ( $comb, $re, $what, $upstream ) = @_;
    $upstream //= $class->new( context => 'dev', namespace => 'platform' );
    my $status = $upstream->status($comb);
    ok $status->is_done, $what.': the status Future is done';
    is $status->get->{reachable}, 0, $what.': unreachable';
    like $status->get->{message}, $re, $what.': the reason';
    is_deeply $status->get->{via}, [ 'dev' ], $what.': via names the context';
    my $endpoints = $upstream->endpoints($comb);
    ok $endpoints->is_failed, $what.': the endpoints Future fails';
    like $endpoints->failure, $re, $what.': ... with the reason';
  };

  my $comb = TestComb::Configurable->new( name => 'nats', namespace => 'getty',
    k8s => Kubernetes::Comb::Client::Fake->new );
  $unreachable->( $comb, qr/\Areading Comb platform\/nats in context dev failed: Context not found: dev/,
    'a missing context' );

  ( $comb ) = setup( objects => [] );
  $unreachable->( $comb, qr/\Areading Comb platform\/nats in context dev failed: Kubernetes API error \(get .*\): 404/,
    'a missing custom resource' );

  my $dev;
  ( $comb, $dev ) = setup();
  $dev->fail_on( get => 'Kubernetes API error (get Comb): 403 combs.comb.internal "nats" is forbidden' );
  $unreachable->( $comb, qr/403 combs\.comb\.internal "nats" is forbidden/, 'no access' );

  $comb = TestComb::Configurable->new( name => 'nats', namespace => 'getty',
    k8s => Kubernetes::Comb::Client::Fake->new( missing_context => 'mine' ) );
  $unreachable->( $comb, qr/Context not found/, 'the Comb\'s own client is broken' );

  $comb = TestComb::Configurable->new( name => 'nats', k8s => Kubernetes::Comb::Client::Fake->new );
  $unreachable->( $comb, qr/\Areading the peer Comb failed: .*has no namespace/, 'the Comb has no namespace',
    $class->new( context => 'dev' ) );
};

subtest 'the Comb itself is no upstream' => sub {
  my ( $comb ) = setup( server_url => $here, namespace => 'platform' );
  my $status = $class->new( context => 'dev' )->status($comb)->get;
  is $status->{reachable}, 0, 'unreachable';
  like $status->{message}, qr/Comb platform\/nats in context dev is this Comb itself/, '... saying why';
};

done_testing;
