use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use YAML::PP;

# k82: building the token_auth stack loads the engine class of every route
# -- in knarr start that is the prefork parent, before the fork, so the
# workers share the classes and no worker's first request waits for the load
# (about 2 s). Class only: no engine is built, no key read, nothing
# connects. A route whose engine class cannot be loaded stops the build
# (knarr start, knarr check) with a message naming the route. Offline: a
# Memory store is injected, the broken engine is an @INC hook.

BEGIN { delete @ENV{ grep { /\A(?:KNARR_|LANGFUSE_)/ } keys %ENV } }
BEGIN { *CORE::GLOBAL::exit = sub { die "EXIT $_[0]\n" } }

# Mistral's engine class fails to compile here.
BEGIN {
  unshift @INC, sub {
    return unless $_[1] eq 'Langertha/Engine/Mistral.pm';
    return \"die qq{broken engine for the test\\n};";
  };
}

use Langertha::Knarr::Config;
use Langertha::Knarr::Stack;
use Langertha::Knarr::Handler::TokenRoutes;
use Langertha::Knarr::TokenStore::Memory;

my $ANTHROPIC = 'Langertha/Engine/Anthropic.pm';

sub token_auth {
  return { backend => 'postgresql', dsn => 'dbi:Pg:host=db.invalid;dbname=x',
    relation => 'r', listen => 'c' };
}

sub stack_for {
  my (%routes) = @_;
  return Langertha::Knarr::Stack->new(
    config      => Langertha::Knarr::Config->new( data => { token_auth => token_auth(), routes => \%routes } ),
    token_store => Langertha::Knarr::TokenStore::Memory->new,
  );
}

subtest 'building the stack loads the route engine classes' => sub {
  ok( !$INC{$ANTHROPIC}, 'the Anthropic engine is not loaded before' )
    or return;
  delete $ENV{K82_PRELOAD_UNSET_KEY};
  my $stack = stack_for(
    claude => { provider => 'anthropic', key_env => 'K82_PRELOAD_UNSET_KEY' },
  );
  ok( !$INC{$ANTHROPIC}, 'constructing the stack loads nothing yet' );
  ok( lives { $stack->build }, 'build lives with the route key unset: no key is read' );
  ok( $INC{$ANTHROPIC}, 'build loaded the Anthropic engine class' );
  ok( Langertha::Engine::Anthropic->can('new'), '... it is usable' );
  is( $stack->router->_engine_cache, {}, 'no engine was built' );
};

subtest 'an upstream route loads the OpenAI engine class' => sub {
  my $handler = Langertha::Knarr::Handler::TokenRoutes->new(
    routes => { local => { upstream => 'http://127.0.0.1:1/v1', key_env => 'K82_PRELOAD_UNSET_KEY' } },
  );
  ok( $INC{'Langertha/Engine/OpenAI.pm'}, 'Langertha::Engine::OpenAI loaded' );
};

subtest 'an engine class that cannot be loaded stops the build, naming the route' => sub {
  my $stack = stack_for(
    eu => { provider => 'mistral', key_env => 'K82_PRELOAD_UNSET_KEY' },
  );
  my $err = dies { $stack->build };
  like( $err, qr/\ALangertha::Knarr::Handler::TokenRoutes: route 'eu': engine Mistral cannot be loaded: broken engine for the test/,
    'croaks with the route, the engine and the cause' );
  like( $err, qr/route 'eu': engine Mistral cannot be loaded: broken engine for the test at \S+ line \d+\.\n\z/,
    '... reported at the caller\'s line (start and check strip it)' );
};

subtest 'knarr check and knarr start stop on it' => sub {
  skip_all 'DBD::Pg not installed (the stack builds the PostgreSQL store first)'
    unless eval { require DBD::Pg; 1 };
  skip_all 'Capture::Tiny required' unless eval { require Capture::Tiny; 1 };
  require Langertha::Knarr::CLI::Cmd::Check;
  require Langertha::Knarr::CLI::Cmd::Start;
  require Langertha::Knarr;
  no warnings qw( redefine once );
  local *Langertha::Knarr::run = sub { return };   # start must never serve here
  {
    package MockMain;
    sub new { bless { config => $_[1], verbose => 0 }, $_[0] }
    sub config  { $_[0]->{config} }
    sub verbose { $_[0]->{verbose} }
  }
  my $file = Path::Tiny->tempfile( SUFFIX => '.yaml' );
  $file->spew_utf8( YAML::PP->new->dump_string( {
    token_auth => token_auth(),
    routes     => { eu => { provider => 'mistral', key_env => 'K82_PRELOAD_UNSET_KEY' } },
  } ) );
  for my $cmd (qw( Check Start )) {
    delete $INC{'Langertha/Engine/Mistral.pm'};   # fail as on a first load, not as a reload
    my ( $out, $err, $died ) = Capture::Tiny::capture( sub {
      my $ok = eval {
        "Langertha::Knarr::CLI::Cmd::$cmd"->new->execute( [], [ MockMain->new("$file") ] );
        1;
      };
      $ok ? '' : $@;
    } );
    is( $died, "EXIT 1\n", "$cmd: exit 1" );
    like( $out . $err, qr/route 'eu': engine Mistral cannot be loaded: broken engine for the test\n/,
      '... the message names the route, without a code location' ) or diag $out . $err;
  }
};

done_testing;
