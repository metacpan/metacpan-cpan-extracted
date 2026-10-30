#!/usr/bin/env perl
# ABSTRACT: The agent tool: its text, call checks, and where the application mounts it (ADR 0020 §3, k153)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::AgentTools;
use Langertha::Raider::Application;
use Langertha::Raider::Context::Agents;
use Langertha::Raider::ToolEffects;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

sub invoke {
  my ( $server, $args ) = @_;
  my ($tool) = grep { $_->name eq 'agent' } @{ $server->tools };
  return $tool->code->( $tool, $args );
}
sub text { $_[0]{content}[0]{text} }

sub catalog {
  my ( %files ) = @_;
  my $dir = path( tempdir( CLEANUP => 1 ) );
  $dir->child($_)->spew_utf8( $files{$_} ) for keys %files;
  return Langertha::Raider::Context::Agents->new( roots => [ { dir => "$dir", source => '.raider/agents' } ] );
}

my $catalog = catalog(
  'reader.md'  => "---\ndescription: Reads only.\ntools: Read, Grep\n---\nbody\n",
  'careful.md' => "---\ndescription: No shell.\ndisallowedTools: Bash, Write\n---\nbody\n",
  'mute.md'    => "---\ndescription: Nothing at all.\ntools: NotebookEdit\n---\nbody\n",
);

subtest 'the tool text lists every agent with its tools' => sub {
  my $tools = Langertha::Raider::AgentTools->new( catalog => $catalog, on_spawn => sub { die 'not called' } );
  my $text = $tools->description;
  like( $text, qr/\ALaunch a new agent to handle complex, multi-step tasks autonomously\./, 'Claude Code opening' );
  like( $text, qr/^Available agent types and the tools they have access to:$/m, 'the list header' );
  like( $text, qr/^- careful: No shell\. \(Tools: All tools except bash, write_file\)$/m, 'disallowed only: all except, raider names' );
  like( $text, qr/^- mute: Nothing at all\. \(Tools: none\)$/m, 'only unknown names: none' );
  like( $text, qr/^- reader: Reads only\. \(Tools: read_file, grep\)$/m, 'allow-list in raider names' );
  like( $text, qr/^- general-purpose: General-purpose agent for researching complex questions.* \(Tools: \*\)$/m,
    'the built-in, all tools' );
  like( $text, qr/no memory of this conversation.*self-contained prompt/, 'the prompt must stand alone' );
  like( $text, qr/final message is returned to you.*with its agent ID and usage/, 'what comes back' );
  like( $text, qr/not visible to the user/, 'the user does not see it' );
  like( $text, qr/^When NOT to use the agent tool:$/m, 'when not to use it' );
  like( $text, qr/Launch multiple agents concurrently whenever possible.*single message with multiple agent calls/,
    'several calls in one message (ADR 0027 section 9)' );
  like( $text, qr/run_in_background.*notified automatically.*<task-notification>/s, 'background runs and their notification' );
  like( $text, qr/use send_message with its agent ID \(or the name you gave it with name\)/, 'send_message continues an agent' );
  unlike( $text, qr/one after the other/, 'no longer one after the other' );
  like( $text, qr/isolation: "worktree" to run the agent in a temporary git worktree.*cleaned up if the agent makes no changes.*worktree path and branch are returned/,
    'isolation in a worktree, in Claude Code\'s words (ADR 0032)' );

  my @tools = @{ $tools->server->tools };
  is( [ map { $_->name } @tools ], ['agent'], 'without on_send: one tool named agent' );
  my ($tool) = @tools;
  is( $tool->description, $text, 'the text is the tool description' );
  is( $tool->input_schema->{required}, [qw( description prompt )], 'description and prompt required' );
  ok( $tool->input_schema->{properties}{$_}, $_.' optional' ) for qw( subagent_type model run_in_background name );
  is( $tool->input_schema->{properties}{model}{enum}, [qw( sonnet opus haiku )], 'model: the three aliases' );
  is( $tool->input_schema->{properties}{run_in_background}{type}, 'boolean', 'run_in_background: boolean' );

  my $both = Langertha::Raider::AgentTools->new( catalog => $catalog, on_spawn => sub { die }, on_send => sub { die } );
  my %by = map { $_->name => $_ } @{ $both->server->tools };
  is( [ map { $_->name } @{ $both->server->tools } ], [qw( agent send_message )], 'with on_send: agent and send_message' );
  is( $by{send_message}->input_schema->{required}, [qw( to message )], 'send_message: to and message required' );
  ok( $by{send_message}->input_schema->{properties}{summary}, 'summary optional' );
  like( $by{send_message}->description, qr/running agent gets the message at its next tool round/, 'send_message text' );
};

subtest 'agent: model, name and run_in_background reach on_spawn; send_message reaches on_send' => sub {
  my ( @spawned, @sent );
  my $tools = Langertha::Raider::AgentTools->new(
    catalog  => $catalog,
    on_spawn => sub { push @spawned, $_[1]; return ( 'ok', 0 ) },
    on_send  => sub { push @sent, $_[0]; return ( 'queued', 0 ) },
  );
  my ($send) = grep { $_->name eq 'send_message' } @{ $tools->server->tools };
  invoke( $tools->server, { description => 'd', prompt => 'p', model => 'haiku', name => 'rev', run_in_background => JSON::MaybeXS->true } );
  is( $spawned[0], { description => 'd', prompt => 'p', subagent_type => 'general-purpose', model => 'haiku', name => 'rev',
    run_in_background => 1 }, 'the call carries model, name and run_in_background' );
  invoke( $tools->server, { description => 'd', prompt => 'p', name => '  ' } );
  is( $spawned[1], { description => 'd', prompt => 'p', subagent_type => 'general-purpose', run_in_background => 0 },
    'a blank name is no name' );
  my $r = invoke( $tools->server, { description => 'd', prompt => 'p', model => 'gpt-4o' } );
  ok( $r->{isError}, 'another model: error' );
  is( text($r), 'Error: model must be one of sonnet, opus, haiku.', 'says which' );
  is( scalar @spawned, 2, 'and starts nothing' );

  # isolation (ADR 0032): "worktree" reaches on_spawn, any other value is an error result.
  invoke( $tools->server, { description => 'd', prompt => 'p', isolation => 'worktree' } );
  is( $spawned[2], { description => 'd', prompt => 'p', subagent_type => 'general-purpose', run_in_background => 0,
    isolation => 'worktree' }, 'isolation worktree reaches on_spawn' );
  $r = invoke( $tools->server, { description => 'd', prompt => 'p', isolation => 'container' } );
  ok( $r->{isError}, 'another isolation: error' );
  is( text($r), 'Error: isolation "container" is not supported; use "worktree".', 'says so' );
  is( scalar @spawned, 3, 'and starts nothing' );
  is( $tools->server->tools->[0]->input_schema->{properties}{isolation}{enum}, ['worktree'], 'isolation: worktree only' );

  $r = $send->code->( $send, { to => 'agent_1', message => 'more', summary => 'a recap' } );
  is( text($r), 'queued', 'send_message answers with on_send' );
  is( $sent[0], { to => 'agent_1', message => 'more', summary => 'a recap' }, 'with the call' );
  $r = $send->code->( $send, { to => ' ', message => 'more' } );
  ok( $r->{isError}, 'an empty to: error' );
  $r = $send->code->( $send, { to => 'agent_1', message => '' } );
  ok( $r->{isError}, 'an empty message: error' );
  is( scalar @sent, 1, 'neither reached on_send' );
};

subtest 'a call goes to on_spawn with the agent; unknown types and empty prompts do not' => sub {
  my @spawned;
  my $tools = Langertha::Raider::AgentTools->new(
    catalog  => $catalog,
    on_spawn => sub { push @spawned, [@_]; return ( $_[1]{subagent_type} eq 'mute' ? ( 'it broke', 1 ) : ( 'agent text', 0 ) ) },
  );

  my $r = invoke( $tools->server, { description => 'Look', prompt => 'Find it.' } );
  ok( !$r->{isError}, 'succeeds' );
  is( text($r), 'agent text', 'the result is what on_spawn returned' );
  is( $spawned[0][0]{name}, 'general-purpose', 'without subagent_type: general-purpose' );
  is( $spawned[0][1], { description => 'Look', prompt => 'Find it.', subagent_type => 'general-purpose',
    run_in_background => 0 }, 'the call' );

  $r = invoke( $tools->server, { description => 'x', prompt => 'y', subagent_type => 'reader' } );
  is( $spawned[1][0]{name}, 'reader', 'the named agent' );

  $r = invoke( $tools->server, { description => 'x', prompt => 'y', subagent_type => 'mute' } );
  ok( $r->{isError}, 'an error from on_spawn is an error result' );
  is( text($r), 'it broke', 'with its text' );

  @spawned = ();
  $r = invoke( $tools->server, { description => 'x', prompt => 'y', subagent_type => 'nope' } );
  ok( $r->{isError}, 'unknown subagent_type: error' );
  is( text($r), "Unknown agent type 'nope'. Available agents: careful, mute, reader, general-purpose, Explore, Plan.",
    'names the available agents' );
  $r = invoke( $tools->server, { description => 'x', prompt => "  \n" } );
  ok( $r->{isError}, 'an empty prompt: error' );
  like( text($r), qr/prompt is empty/, 'says so' );
  is( \@spawned, [], 'neither started a subagent' );
};

sub app {
  my ( %args ) = @_;
  return Langertha::Raider::Application->new(
    root    => tempdir( CLEANUP => 1 ),
    engine  => 'openai',
    api_key => 'test',
    detect  => 0,
    %args,
  );
}

subtest 'the application mounts the agent tool below the depth limit' => sub {
  my $app = app();
  is( $app->max_agent_depth, 3, 'default depth 3 (ADR 0027)' );
  ok( ( grep { $_->name eq 'agent' } $app->_mounted_tools ), 'agent mounted at depth 0' );
  like( $app->mission, qr/^  - agent\(description, prompt, \[isolation\], \[model\], \[name\], \[run_in_background\], \[subagent_type\]\)$/m,
    'and described' );
  like( $app->mission, qr/^  - send_message\(to, message, \[summary\]\)$/m, 'send_message beside it (ADR 0027 section 5)' );

  my $none = app( max_agent_depth => 0 );
  ok( !( grep { $_->name eq 'agent' || $_->name eq 'send_message' } $none->_mounted_tools ),
    'max_agent_depth 0: no agent tool, no send_message' );
  unlike( $none->mission, qr/agent\(|send_message\(/, 'nor their description' );

  for my $name (qw( agent send_message )) {
    is( Langertha::Raider::ToolEffects->effects_for($name), [], $name.': no effect class of its own' );
    my ($entry) = grep { $_->{name} eq $name } @{ $app->explain_config->{tools} };
    ok( $entry, 'config explain lists it' ) && is( $entry->{effects}, [], 'known, no effects' );
  }
};

subtest 'build_subagent_engine: the main engine class and arguments, model replaceable' => sub {
  my $app = app( model => 'gpt-4o-mini' );
  my $engine = $app->build_subagent_engine( mcp_servers => [] );
  isa_ok( $engine, 'Langertha::Engine::OpenAI' );
  is( $engine->chat_model, 'gpt-4o-mini', 'inherits the model' );
  is( $engine->mcp_servers, [], 'over the given clients' );
  is( $app->build_subagent_engine( mcp_servers => [], model => 'gpt-other' )->chat_model, 'gpt-other',
    'a model given replaces it' );
};

done_testing;
