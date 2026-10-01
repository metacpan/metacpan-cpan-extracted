use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Future;
use Kubernetes::Comb;
use Kubernetes::Comb::Client::Fake;
use TestComb::Configurable;
use TestComb::Fixtures qw( comb_cr deployment );

{
  package TestComb::Upstream::Probe;
  use Moo;
  with 'Kubernetes::Comb::Role::Upstream';
  has args => ( is => 'ro' );
  around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
    return { args => {@args} };
  };
  sub status    { Future->done( { reachable => 1, phase => 'Running' } ) }
  sub endpoints { Future->done( [] ) }
}

# The short form Probe => (...) names this one.
{
  package Kubernetes::Comb::Upstream::Probe;
  use Moo;
  extends 'TestComb::Upstream::Probe';
}

# Has the methods, but does not do the role.
{
  package TestComb::Upstream::Duck;
  use Moo;
  sub status    { }
  sub endpoints { }
}

# Not an upstream either, and counts how often it is built.
{
  package TestComb::NotAnUpstream;
  our $BUILT = 0;
  sub new       { $BUILT++; return bless {}, shift }
  sub status    { }
  sub endpoints { }
}

# A Comb class with an upstream method; what it answers is set per test.
{
  package TestComb::WithUpstream;
  use Moo;
  extends 'TestComb::Configurable';
  our @ANSWER;
  our $ASKED = 0;
  sub upstream { $ASKED++; return @ANSWER }
}

sub comb {
  my ( %args ) = @_;
  my $spec  = delete $args{spec};
  my $class = delete $args{class} // 'TestComb::WithUpstream';
  my $k8s   = Kubernetes::Comb::Client::Fake->new;
  my %crd;
  if ($spec) {
    my $cr = comb_cr( name => 'nats', class => $class, spec => $spec );
    $k8s->add($cr);
    %crd = ( crd => $k8s->object( Comb => 'nats', namespace => 'platform' ) );
  }
  return ( $class->new(
    ( %crd ? () : ( name => 'nats', namespace => 'platform' ) ),
    %crd,
    k8s   => $k8s,
    parts => [ deployment('nats') ],
    %args
  ), $k8s );
}

# What the resolution gives: [ $upstream ] or [ failure message ].
sub resolved {
  my ( $comb ) = @_;
  my $f = $comb->_resolve_upstream;
  return $f->is_failed ? [ 'failed: '.$f->failure ] : [ $f->get ];
}

sub is_local {
  my ( $comb, $what ) = @_;
  my $got = resolved($comb);
  ok @$got == 0 || ( @$got == 1 && !defined $got->[0] ), $what
    or diag explain $got;
}

sub is_probe {
  my ( $comb, $class, $args, $what ) = @_;
  my ( $upstream ) = @{ resolved($comb) };
  is ref $upstream, $class, $what;
  is_deeply $upstream->args, $args, $what.': built with its arguments' if ref $upstream;
}

sub fails_like {
  my ( $comb, $re, $what ) = @_;
  my ( $got ) = @{ resolved($comb) };
  like $got // '', qr/\Afailed: .*$re/s, $what;
}

sub condition {
  my ( $status, $type ) = @_;
  my ( $condition ) = grep { $_->type eq $type } @{ $status->conditions // [] };
  return $condition;
}

subtest 'no source: local' => sub {
  is_local( ( comb( class => 'TestComb::Configurable' ) )[0], 'nothing anywhere' );
  is_local( ( comb( class => 'TestComb::Configurable', spec => {} ) )[0], 'a custom resource without upstream' );
  local @TestComb::WithUpstream::ANSWER = ();
  is_local( ( comb() )[0], 'a class method answering nothing' );
  local @TestComb::WithUpstream::ANSWER = ( undef );
  is_local( ( comb() )[0], 'a class method answering undef' );
};

subtest 'the upstream argument comes first' => sub {
  local $TestComb::WithUpstream::ASKED = 0;
  my $given;
  my ( $comb ) = comb(
    spec     => { upstream => { class => 'TestComb::Upstream::Probe' } },
    upstream => sub { $given = [@_]; return }
  );
  is_local( $comb, 'a coderef answering nothing is final: local' );
  is_deeply $given, [ $comb ], 'the coderef gets the Comb';
  is $TestComb::WithUpstream::ASKED, 0, 'the class method is not asked';

  ( $comb ) = comb( spec => { upstream => { class => 'TestComb::Upstream::Probe' } }, upstream => undef );
  is_local( $comb, 'undef is final: local' );
  is $TestComb::WithUpstream::ASKED, 0, 'the class method is not asked';

  my $object = TestComb::Upstream::Probe->new( url => 'x' );
  is resolved( ( comb( upstream => $object ) )[0] )->[0], $object, 'an object is taken as it is';
  is resolved( ( comb( upstream => sub { $object } ) )[0] )->[0], $object, '... also from the coderef';

  is_probe( ( comb( upstream => sub { '+TestComb::Upstream::Probe' => ( url => 'x' ) } ) )[0],
    'TestComb::Upstream::Probe', { url => 'x' }, '+Full::Class => (...)' );
  is_probe( ( comb( upstream => sub { Probe => ( context => 'dev' ) } ) )[0],
    'Kubernetes::Comb::Upstream::Probe', { context => 'dev' }, 'Name => (...)' );
  is_probe( ( comb( upstream => sub { Future->done( '+TestComb::Upstream::Probe' => ( a => 1 ) ) } ) )[0],
    'TestComb::Upstream::Probe', { a => 1 }, 'a Future of the answer' );
  is_local( ( comb( upstream => sub { undef } ) )[0], 'undef from the coderef: local' );
  is_probe( ( comb( upstream => { class => 'TestComb::Upstream::Probe', context => 'dev' } ) )[0],
    'TestComb::Upstream::Probe', { context => 'dev' }, 'a hashref as in the custom resource' );
  is_probe( ( comb( upstream => [ '+TestComb::Upstream::Probe' => ( context => 'dev' ) ] ) )[0],
    'TestComb::Upstream::Probe', { context => 'dev' }, 'an arrayref of the Perl form' );
};

subtest 'then the custom resource' => sub {
  local $TestComb::WithUpstream::ASKED = 0;
  local @TestComb::WithUpstream::ANSWER = ( '+TestComb::Upstream::Probe' );
  my ( $comb ) = comb( spec => { upstream => undef } );
  is_local( $comb, 'spec.upstream null is final: local' );
  is $TestComb::WithUpstream::ASKED, 0, 'the class method is not asked';

  ( $comb ) = comb( spec => { upstream => { class => 'TestComb::Upstream::Probe', context => 'dev' } } );
  is_probe( $comb, 'TestComb::Upstream::Probe', { context => 'dev' }, 'spec.upstream with a class' );
  is $TestComb::WithUpstream::ASKED, 0, 'the class method is not asked';

  fails_like( ( comb( spec => { upstream => { class => 'Probe' } } ) )[0], qr/Probe\.pm/,
    'the custom resource holds full class names: no short forms' );
  fails_like( ( comb( spec => { upstream => { context => 'dev' } } ) )[0], qr/spec\.upstream names no class/,
    'no class' );
};

subtest 'then the class method' => sub {
  local $TestComb::WithUpstream::ASKED = 0;
  local @TestComb::WithUpstream::ANSWER = ( Probe => ( context => 'prod' ) );
  my ( $comb ) = comb( spec => {} );
  is_probe( $comb, 'Kubernetes::Comb::Upstream::Probe', { context => 'prod' }, 'Name => (...)' );
  is $TestComb::WithUpstream::ASKED, 1, 'asked';
};

subtest 'short names' => sub {
  my ( $comb ) = comb();
  is $comb->_upstream_class('K8s'), 'Kubernetes::Comb::Upstream::K8s', 'K8s';
  is $comb->_upstream_class('Static'), 'Kubernetes::Comb::Upstream::Static', 'Static';
  is $comb->_upstream_class('+MyApp::Upstream::Catalog'), 'MyApp::Upstream::Catalog', '+Full::Class';
};

subtest 'answers that do not resolve' => sub {
  fails_like( ( comb( upstream => sub { die "no layers today\n" } ) )[0], qr/no layers today/, 'a dying coderef' );
  fails_like( ( comb( upstream => TestComb::Upstream::Duck->new ) )[0],
    qr/TestComb::Upstream::Duck does not do Kubernetes::Comb::Role::Upstream/, 'an object not doing the role' );
  fails_like( ( comb( upstream => sub { '+TestComb::Upstream::Duck' } ) )[0],
    qr/does not do Kubernetes::Comb::Role::Upstream/, 'a class not doing the role' );
  fails_like( ( comb( upstream => sub { '+TestComb::Upstream::Nowhere' } ) )[0],
    qr/TestComb\/Upstream\/Nowhere\.pm/, 'a class that does not load' );
  fails_like( ( comb( upstream => sub { Probe => 'context' } ) )[0], qr/needs key\/value pairs/, 'odd arguments' );
  fails_like( ( comb( upstream => sub { ( TestComb::Upstream::Probe->new ) x 2 } ) )[0],
    qr/one upstream object or hashref, not a list/, 'two objects' );
  fails_like( ( comb( upstream => sub { \'K8s' } ) )[0], qr/got a SCALAR reference/, 'something else' );
};

subtest 'a class is checked before it is built' => sub {
  for my $case (
    [ 'spec.upstream', spec => { upstream => { class => 'TestComb::NotAnUpstream', url => 'x' } } ],
    [ 'a hashref',     upstream => { class => 'TestComb::NotAnUpstream', url => 'x' } ],
    [ '+Full::Class',  upstream => sub { '+TestComb::NotAnUpstream' => ( url => 'x' ) } ]
  ) {
    my ( $what, @args ) = @$case;
    local $TestComb::NotAnUpstream::BUILT = 0;
    fails_like( ( comb( class => 'TestComb::Configurable', @args ) )[0],
      qr/TestComb::NotAnUpstream does not do Kubernetes::Comb::Role::Upstream/, $what.': refused' );
    is $TestComb::NotAnUpstream::BUILT, 0, $what.': never constructed';
  }
};

subtest 'reconcile with an active upstream' => sub {
  my ( $comb, $k8s ) = comb( class => 'TestComb::Configurable', upstream => sub { '+TestComb::Upstream::Probe' } );
  my $status = $comb->reconcile->get;
  is $status->phase, 'Running', 'the upstream path: borrowed, Running';
  is condition( $status, 'Ready' )->reason, 'Borrowed', '... Borrowed';
  like condition( $status, 'Ready' )->message, qr/TestComb::Upstream::Probe/, '... naming the upstream';
  ok !$k8s->calls_of('ensure'), 'nothing deployed locally, no endpoints to bridge';
  is_deeply $status->endpoints, [], 'no local endpoints published';
  is $status->upstream->class, 'TestComb::Upstream::Probe', 'status.upstream names it';
};

subtest 'resolution is the first step' => sub {
  my ( $comb ) = comb( class => 'TestComb::Configurable', spec => { enabled => 0 }, upstream => sub { die "boom\n" } );
  my $status = $comb->reconcile->get;
  is $status->phase, 'Error', 'a failing resolution comes before Disabled';
  is condition( $status, 'Ready' )->reason, 'UpstreamFailed', '... UpstreamFailed';
  like condition( $status, 'Ready' )->message, qr/resolving the upstream failed: boom/, '... saying so';
  is_deeply $status->endpoints, [], 'no endpoints published, local or not is unknown';

  my $upstream = sub { '+TestComb::Upstream::Probe' };
  ( $comb ) = comb( class => 'TestComb::Configurable', spec => { enabled => 0 }, upstream => $upstream );
  is $comb->reconcile->get->phase, 'Disabled', 'with an upstream: Disabled still applies';
  ( $comb ) = comb( class => 'TestComb::Configurable', needs => [ 'db' ], upstream => $upstream );
  is $comb->reconcile->get->phase, 'Blocked', '... Blocked too';
  ( $comb ) = comb( class => 'TestComb::Configurable', missing => [ 'x' ], upstream => $upstream );
  is $comb->reconcile->get->phase, 'NeedsConfig', '... and NeedsConfig';
};

done_testing;
