#!/usr/bin/env perl
# ABSTRACT: No session embeddings unless a history tool is mounted (k162)
use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
use Path::Tiny;
use Future;
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::MockAI qw( mock_app );
use Langertha::Raider;

# An engine that can embed and counts the requests. Before k162 the
# application's raider sent one per history entry although it mounts no tool
# that reads them (and a provider without an embeddings endpoint answered 404).
my $requests = 0;
{
  package Test::Embedding::Engine;
  use Moose;
  extends 'Langertha::Engine::Virtual';
  # Claims the role without composing it: composing would replace the
  # virtual transport with real HTTP.
  around does => sub { my ($o, $s, $r) = @_; return 1 if $r eq 'Langertha::Role::Embedding'; return $s->$o($r) };
  sub simple_embedding_f { $requests++; return Future->done([ 1, 0 ]) }
  __PACKAGE__->meta->make_immutable;
}
{
  package Test::Embedding::App;
  use Moose;
  extends 'Test::Raider::MockAI::App';
  sub _build_engine {
    my ( $self ) = @_;
    return Test::Embedding::Engine->new(
      script => [], fallback => Langertha::Virtual::Rules::answer('done'),
      langfuse_enabled => 0, mcp_servers => $self->_mcps,
    );
  }
  __PACKAGE__->meta->make_immutable;
}

my $root = Path::Tiny->tempdir;
$ENV{HOME} = Path::Tiny->tempdir->realpath->stringify;

subtest 'the application embeds nothing: no history tool is mounted' => sub {
  $requests = 0;
  my $app = Test::Embedding::App->new(
    engine_name => 'openai', api_key => 'mock', root => $root->stringify,
    loadguard => Langertha::Raider::Loadguard->new( env => { LOADGUARD_THROTTLE => 0 } ),
  );
  ok $app->_engine->does('Langertha::Role::Embedding'), 'the engine could embed';
  $app->run('hello there');
  ok scalar @{ $app->_raider->session_history }, 'the run left session history';
  is $requests, 0, 'no embedding request';
  ok $app->_raider->no_session_embeddings, 'the raider has them off';
  is $app->explain_config->{session_embeddings},
    { enabled => 0, reason => 'no session history tool is mounted' }, 'config explain says so';
};

subtest 'a raider with the history tool keeps embedding' => sub {
  $requests = 0;
  my $engine = Test::Embedding::Engine->new(
    script => [], fallback => Langertha::Virtual::Rules::answer('done'), langfuse_enabled => 0,
  );
  my $raider = Langertha::Raider->new( engine => $engine, raider_mcp => { session_history => 1 } );
  $raider->add_session_history({ role => 'user', content => 'hello there' });
  ok $requests > 0, 'embedded';
};

done_testing;
