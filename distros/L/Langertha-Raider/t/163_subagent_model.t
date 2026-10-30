#!/usr/bin/env perl
# ABSTRACT: A subagent's model: an agent file's model under the Anthropic API, inherited elsewhere, same loop (ADR 0020 section 5, k153)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home clear_engine_env );
isolate_home();
clear_engine_env();
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Path::Tiny;
use Scalar::Util qw( refaddr );
use Langertha::Engine::Anthropic;
use Langertha::Engine::OpenAI;
use Langertha::Raider::Application;
use Langertha::Raider::Subagent;
use Test::Raider::MockAI qw( mock_app );

delete @ENV{qw( RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

# Engine classes that only exist here: one that is the Anthropic API (a
# subclass of it), one that is not. Nothing is built from them -- the
# subagent asks the caller's engine class whether a model may be mapped.
{ package Test::Raider::Model::FakeAnthropic; use Moose; extends 'Langertha::Engine::Anthropic'; __PACKAGE__->meta->make_immutable }
{ package Test::Raider::Model::FakeOther;     use Moose; extends 'Langertha::Engine::OpenAI';    __PACKAGE__->meta->make_immutable }

# The mock application with the caller's engine class swapped; the
# subagent's engine still answers from the script and records the model it
# was given.
{
  package Test::Raider::Model::App;
  use Moose;
  extends 'Test::Raider::MockAI::App';
  has fake_class => ( is => 'ro', required => 1 );
  has built => ( is => 'ro', default => sub { [] } );
  sub _engine_class { $_[0]->fake_class }
  around build_subagent_engine => sub {
    my ( $orig, $self, %o ) = @_;
    push @{ $self->built }, { %o };
    return $self->$orig(%o);
  };
  __PACKAGE__->meta->make_immutable;
}

# A temporary directory, held until the end of the test.
my @tmp;
sub tmp { push @tmp, Path::Tiny->tempdir; return $tmp[-1]->realpath }

sub run_agent {
  my ( %o ) = @_;
  my $root = tmp();
  $root->child('CLAUDE.md')->spew_utf8("Project.\n");
  $root->child('.claude/agents/pick.md')->touchpath->spew_utf8(
    "---\nname: pick\ndescription: Picks.\nmodel: $o{model}\n---\nPICK-BODY\n");
  my @events;
  my $app = Test::Raider::Model::App->new(
    root        => "$root",
    engine      => 'anthropic',
    api_key     => 'mock',
    fake_class  => $o{class},
    loadguard   => Langertha::Raider::Loadguard->new( env => { LOADGUARD_THROTTLE => 0 } ),
    on_event    => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    ( $o{agent_models} ? ( agent_models => $o{agent_models} ) : () ),
    script      => [
      { tool_calls => [ [ agent => { description => 'd', prompt => 'CHILD', subagent_type => 'pick' } ] ] },
      { text => 'child' },
      { text => 'parent' },
    ],
  );
  is( '' . $app->run('go'), 'parent', 'the caller answers' );
  my ($started) = grep { $_->{type} eq 'agent.started' } @events;
  return ( $app, $started );
}

subtest 'an alias under the Anthropic API: an engine with that model' => sub {
  my ( $app, $started ) = run_agent( class => 'Test::Raider::Model::FakeAnthropic', model => 'sonnet' );
  is( $app->built->[0]{model}, 'claude-sonnet-5-5', 'build_subagent_engine gets the mapped model' );
  is( $started->{model}, 'claude-sonnet-5-5', 'agent.started carries the model really used' );
};

subtest 'agent_models overrides an alias; a full claude-* id stays' => sub {
  my ( $app, $started ) = run_agent( class => 'Test::Raider::Model::FakeAnthropic', model => 'haiku',
    agent_models => { haiku => 'claude-haiku-4-5' } );
  is( $started->{model}, 'claude-haiku-4-5', 'the configured model' );
  ( $app, $started ) = run_agent( class => 'Test::Raider::Model::FakeAnthropic', model => 'claude-opus-4-1' );
  is( $started->{model}, 'claude-opus-4-1', 'the id as written' );
};

subtest 'not the Anthropic API, or inherit: the caller\'s model' => sub {
  my ( $app, $started ) = run_agent( class => 'Test::Raider::Model::FakeOther', model => 'sonnet' );
  ok( !exists $app->built->[0]{model}, 'no model handed on' );
  is( $started->{model}, 'virtual', 'the caller\'s model' );
  ( $app, $started ) = run_agent( class => 'Test::Raider::Model::FakeAnthropic', model => 'inherit' );
  ok( !exists $app->built->[0]{model}, 'inherit: no model' );
  is( $started->{model}, 'virtual', 'inherited' );
  ( $app ) = run_agent( class => 'Test::Raider::Model::FakeOther', model => 'opus' );
  my $sub = Langertha::Raider::Subagent->new(
    app => $app, agent => $app->context->agent_catalog->find('pick'), depth => 1, prompt => 'x',
    caller_servers => [], on_caller_event => sub { },
  );
  like( $sub->model_resolution, { inherit => 1, reason => qr/\Amodel opus: inherited, engine anthropic is not the Anthropic API\z/ },
    'model_resolution says why' );
};

subtest 'the real engine path: same class and arguments, the model replaced, the same loop' => sub {
  my $root = tmp();
  my $app = Langertha::Raider::Application->new(
    root    => "$root",
    engine  => 'anthropic',
    api_key => 'test-key-not-used',
    loadguard => Langertha::Raider::Loadguard->new( env => { LOADGUARD_THROTTLE => 0 } ),
  );
  my $main = $app->_engine;
  my $client = $app->_mcp_client( $app->_tool_servers->[0] );
  my $sub = $app->build_subagent_engine( mcp_servers => [$client], model => 'claude-haiku-5-5' );
  isa_ok( $sub, ['Langertha::Engine::Anthropic'], 'the caller\'s class' );
  is( $sub->chat_model, 'claude-haiku-5-5', 'with the model' );
  is( $sub->api_key, $main->api_key, 'and the caller\'s arguments' );
  isnt( $main->chat_model, 'claude-haiku-5-5', 'the caller keeps its model' );
  is( refaddr $sub->async_loop, refaddr $app->loop, 'the engine is on the application\'s loop' );
  is( refaddr $client->loop, refaddr $app->loop, 'its MCP clients too' );
  is( $app->build_subagent_engine( mcp_servers => [] )->chat_model, $main->chat_model, 'without model: inherited' );
  $app->loop->remove($client);
};

done_testing;
