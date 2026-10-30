#!/usr/bin/env perl
# ABSTRACT: Parallel agent calls and the concurrency limit: agent and send_message as async tools (ADR 0027 §9, k161)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use JSON::MaybeXS ();
use Path::Tiny;
use Time::HiRes qw( time );
use Test::Raider::MockAI qw( mock_app );
use Test::Raider::SlowAI qw( slow_app );

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS
  CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH )};

# A subagent engine whose delay depends on the request: CHILD-PROMPT (the
# first request of the child below) waits a second, every other one 50 ms.
{
  package T216::SubEngine;
  use Moose;
  extends 'Test::Raider::MockAI::SubEngine';
  has loop => ( is => 'ro' );
  around async_request_f => sub {
    my ( $orig, $self, $request, @args ) = @_;
    my $body = eval { $request->content } // '';
    my $delay = $body =~ /CHILD-PROMPT/ && $body !~ /agentId/ ? 1 : 0.05;
    return $self->loop->delay_future( after => $delay )->then( sub { $self->$orig( $request, @args ) } );
  };
  __PACKAGE__->meta->make_immutable;
}
{
  package T216::App;
  use Moose;
  extends 'Test::Raider::SlowAI::App';
  sub build_subagent_engine {
    my ( $self, %o ) = @_;
    return T216::SubEngine->new( main => $self->_engine, langfuse_enabled => 0,
      mcp_servers => $o{mcp_servers}, loop => $self->loop );
  }
  __PACKAGE__->meta->make_immutable;
}

my @roots;
sub root { my $dir = Path::Tiny->tempdir; push @roots, $dir; $dir->realpath }

# Events with the time they came.
sub collect { my ( $list ) = @_; return sub { my ( $type, %p ) = @_; push @$list, { type => $type, at => time, %p } } }

sub results_of { my ( $app, $name ) = @_; [ grep { $_->{tool_call}->name eq $name } @{ $app->mock_engine->results } ] }
sub texts_of   { [ map { $_->{result}{content}[0]{text} } @{ results_of(@_) } ] }

sub of_type { my ( $events, $type, %match ) = @_;
  [ grep { my $e = $_; $e->{type} eq $type && !grep { ( $e->{$_} // '' ) ne $match{$_} } keys %match } @$events ] }

my $limit_text = 'Concurrent subagent limit reached (1 running). Do not retry this call now; wait for running agents to finish.';

subtest 'two agent calls of one turn run at the same time; results in call order, each its own trailer' => sub {
  my @events;
  my $app = slow_app(
    root      => ''.root(),
    sub_delay => 0.4,
    on_event  => collect( \@events ),
    script    => [
      { tool_calls => [ [ agent => { description => 'One', prompt => 'P1' } ], [ agent => { description => 'Two', prompt => 'P2' } ] ] },
      # answered in the order the requests were made: agent_1 first, it goes on with a tool
      { tool_calls => [ [ list_files => { path => '.' } ] ] },
      { text => 'REPORT TWO' },
      { text => 'REPORT ONE' },
      { text => 'done' },
    ],
  );
  my $session = $app->create_session;
  is( $app->run_prompt( 'go', session => $session )->{response}, 'done', 'the caller answers' );

  my @started  = @{ of_type( \@events, 'agent.started' ) };
  my @finished = @{ of_type( \@events, 'agent.finished' ) };
  is( [ map { $_->{agent_id} } @started ],  [qw( agent_1 agent_2 )], 'both started, in call order' );
  is( [ map { $_->{agent_id} } @finished ], [qw( agent_2 agent_1 )], 'agent_2 finished first' );
  ok( $started[1]{at} < $finished[0]{at}, 'the second started before the first one finished: they overlap' );
  ok( $finished[-1]{at} - $started[0]{at} < 1.1, 'together in less time than one after the other (3 x 0.4s)' );
  is( [ map { $_->{call} } @started ], [qw( c1 c2 )], 'each knows its own agent call' );

  my $texts = texts_of( $app, 'agent' );
  like( $texts->[0], qr{\AREPORT ONE\nagentId: agent_1 \(use send_message with to: 'agent_1' to continue this agent\)\n<usage>subagent_tokens: \d+\ntool_uses: 1\n}, 'the first call gets agent_1\'s report' );
  like( $texts->[1], qr{\AREPORT TWO\nagentId: agent_2 .*\ntool_uses: 0\n}s, 'the second agent_2\'s' );
  my $turn = $app->mock_engine->requests->[-1]{messages};
  my @tool_msgs = grep { $_->{role} eq 'tool' } @$turn;
  is( scalar @tool_msgs, 2, 'two tool results go back' );
  like( $tool_msgs[0]{content}, qr/REPORT ONE/, 'in call order' );

  my @results = @{ of_type( \@events, 'tool.result', name => 'agent' ) };
  is( [ map { $_->{call} } @results ], [qw( c2 c1 )], 'tool.result in finishing order, each with its own call id' );
  like( $results[0]{content}, qr/agentId: agent_2/, 'c2 is agent_2\'s result' );
  like( $results[1]{content}, qr/agentId: agent_1/, 'c1 is agent_1\'s' );
  is( $app->tasks->get('agent_1')->{tool_use_id}, 'c1', 'the registry: agent_1 for c1' );
  is( $app->tasks->get('agent_2')->{tool_use_id}, 'c2', 'agent_2 for c2' );

  my $journal = $app->session_store->read( $session->id );
  is( $journal->unknown_calls, [], 'the journal pairs every tool.call with its tool.result' );
};

subtest 'Ctrl-C cuts off both calls of a group; the run ends after the agents' => sub {
  my @events;
  my $app;
  $app = slow_app(
    root      => ''.root(),
    sub_delay => 30,
    on_event  => sub {
      my ( $type, %p ) = @_;
      collect( \@events )->(@_);
      $app->cancel_run if $type eq 'agent.started' && $p{call} eq 'c2';
    },
    script    => [
      { tool_calls => [ [ agent => { description => 'One', prompt => 'P1' } ], [ agent => { description => 'Two', prompt => 'P2' } ] ] },
      { text => 'never' },
    ],
  );
  my $session = $app->create_session;
  my $t0 = time;
  my $outcome = $app->run_prompt( 'go', session => $session );
  ok( time - $t0 < 10, 'without waiting for the agents\' model' );
  is( $outcome->{status}, 'cancelled', 'the run is cancelled' );
  is( [ map { [ $_->{call}, $_->{status} ] } @{ of_type( \@events, 'tool.result', name => 'agent' ) } ],
    [ [ c1 => 'cancelled' ], [ c2 => 'cancelled' ] ], 'both agent calls are cut off' );
  is( [ sort map { $_->{agent_id}.' '.$_->{status} } @{ of_type( \@events, 'agent.finished' ) } ],
    [ 'agent_1 cancelled', 'agent_2 cancelled' ], 'both agents end cancelled' );
  my ($run_end) = grep { $_->{type} eq 'run.state' && $_->{state} eq 'cancelled' } @events;
  ok( $run_end, 'the run ends cancelled' );
  ok( !grep( { $_->{type} eq 'agent.finished' && $_->{at} > $run_end->{at} } @events ), 'before the run ends' );
  is( [ map { $_->{status} } map { $app->tasks->get($_) } qw( agent_1 agent_2 ) ], [qw( killed killed )], 'the registry says killed' );
  is( [ grep { defined } values %{ $app->_live_subagents } ], [], 'no live subagent left' );
};

subtest 'a call of another tool between them ends the group' => sub {
  my @events;
  my $app = slow_app(
    root      => ''.root(),
    sub_delay => 0.05,
    on_event  => collect( \@events ),
    script    => [
      { tool_calls => [ [ agent => { description => 'One', prompt => 'P1' } ], [ list_files => { path => '.' } ],
        [ agent => { description => 'Two', prompt => 'P2' } ] ] },
      { text => 'R1' },
      { text => 'R2' },
      { text => 'done' },
    ],
  );
  is( '' . $app->run('go'), 'done', 'the caller answers' );
  my ($first_done) = @{ of_type( \@events, 'agent.finished', agent_id => 'agent_1' ) };
  my ($second)     = @{ of_type( \@events, 'agent.started', agent_id => 'agent_2' ) };
  ok( $first_done->{at} <= $second->{at}, 'agent_2 starts after agent_1 finished' );
  is( [ map { $_->{tool_call}->name } @{ $app->mock_engine->results }[-3 .. -1] ], [qw( agent list_files agent )],
    'results in call order' );
  like( texts_of( $app, 'agent' ), [ qr/\AR1\n/, qr/\AR2\n/ ], 'each its report' );
};

subtest 'max_concurrent_agents: the call beyond the limit is refused, nothing starts' => sub {
  my @events;
  my $app = slow_app(
    root                  => ''.root(),
    sub_delay             => 0.1,
    max_concurrent_agents => 1,
    on_event              => collect( \@events ),
    script                => [
      { tool_calls => [ [ agent => { description => 'One', prompt => 'P1' } ], [ agent => { description => 'Two', prompt => 'P2' } ] ] },
      { text => 'R1' },
      { text => 'done' },
    ],
  );
  is( $app->max_concurrent_agents, 1, 'from the constructor' );
  is( '' . $app->run('go'), 'done', 'the caller answers' );
  my $agent = results_of( $app, 'agent' );
  like( $agent->[0]{result}{content}[0]{text}, qr/\AR1\nagentId: agent_1 /, 'the first runs' );
  is( $agent->[1]{result}{content}[0]{text}, $limit_text, 'the second is refused with the exact text' );
  ok( $agent->[1]{result}{isError}, 'as an error' );
  is( [ map { $_->{agent_id} } @{ of_type( \@events, 'agent.started' ) } ], ['agent_1'], 'only agent_1 started' );
  ok( !$app->tasks->get('agent_2'), 'no agent_2 in the registry' );
};

subtest 'send_message: resuming beyond the limit is refused the same way' => sub {
  my $app = slow_app(
    root                  => ''.root(),
    sub_delay             => 0.3,
    max_concurrent_agents => 1,
    script                => [
      { tool_calls => [ [ agent => { description => 'Fg', prompt => 'P1' } ] ] },
      { text => 'R1' },
      { tool_calls => [ [ agent => { description => 'Bg', prompt => 'P2', run_in_background => \1 } ],
        [ send_message => { to => 'agent_1', message => 'more' } ] ] },
      { text => 'done' },
    ],
  );
  is( '' . $app->run('go'), 'done', 'the caller answers' );
  my ($sent) = @{ results_of( $app, 'send_message' ) };
  is( $sent->{result}{content}[0]{text}, $limit_text, 'refused while agent_2 runs' );
  ok( $sent->{result}{isError}, 'as an error' );
  is( $app->tasks->get('agent_1')->{status}, 'completed', 'agent_1 was not resumed' );
  $app->stop_background;
};

subtest 'max_concurrent_agents: config key, Claude env, default; config explain' => sub {
  my $plain = mock_app( root => ''.root() );
  is( $plain->max_concurrent_agents, 20, 'default 20' );

  my $root = root();
  $root->child('.raider/config.yml')->touchpath->spew_utf8("max_concurrent_agents: 3\n");
  is( mock_app( root => "$root" )->max_concurrent_agents, 3, 'from the config' );

  local $ENV{CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS} = 5;
  is( mock_app( root => ''.root() )->max_concurrent_agents, 20, 'the env var only in the Claude layout' );
  my $claude = root();
  $claude->child('CLAUDE.md')->spew_utf8("Project.\n");
  my $app = mock_app( root => "$claude" );
  is( $app->max_concurrent_agents, 5, 'from CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS in the Claude layout' );
  my ($entry) = grep { $_->{key} eq 'max_concurrent_agents' } @{ $app->explain_config->{values} };
  like( $entry, { value => 5, source => 'env CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS' }, 'config explain names the source' );

  local $ENV{CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS} = 'many';
  my $bad = mock_app( root => "$claude" );
  is( $bad->max_concurrent_agents, 20, 'a value that does not fit falls back to the default' );
  like( $bad->explain_config->{ignored}, bag { item { key => 'env CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS', reason => 'not a positive integer' }; etc },
    'and is listed as ignored' );

  my $zero = root();
  $zero->child('.raider/config.yml')->touchpath->spew_utf8("max_concurrent_agents: 0\n");
  my $z = mock_app( root => "$zero" );
  is( $z->max_concurrent_agents, 20, 'the config key must be positive' );
  like( $z->explain_config->{ignored}, bag { item { key => 'max_concurrent_agents' }; etc }, 'else ignored' );
};

subtest 'a foreground agent inside a background agent does not hold up the main run' => sub {
  my $app = T216::App->new(
    root        => ''.root(),
    engine_name => 'openai',
    api_key     => 'mock',
    loadguard   => Langertha::Raider::Loadguard->new( env => { LOADGUARD_THROTTLE => 0 } ),
    delay       => 0.3,
    script      => [
      { tool_calls => [ [ agent => { description => 'Parent', prompt => 'PARENT', run_in_background => \1 } ] ] },
      { tool_calls => [ [ agent => { description => 'Child', prompt => 'CHILD-PROMPT' } ] ] },
      { text => 'main done' },
      { text => 'C REPORT' },
      { text => 'P REPORT' },
    ],
  );
  my $t0 = time;
  is( '' . $app->run('go'), 'main done', 'the main run answers' );
  ok( time - $t0 < 0.95, 'before the child in the background agent has its answer' );
  is( $app->tasks->get('agent_2')->{status}, 'running', 'the child still runs' );
  is( $app->tasks->get('agent_2')->{recipient}, 'agent_1', 'as a foreground agent of agent_1' );
  is( $app->wait_for_notifications, 1, 'the background agent notifies' );
  my ($item) = $app->take_notifications;
  like( $item->{text}, qr{<task-id>agent_1</task-id>.*<result>P REPORT</result>}s, 'with its report' );
  like( texts_of( $app, 'agent' )->[-1], qr/\AC REPORT\nagentId: agent_2 /, 'the child\'s result reached its caller' );
};

subtest 'a deny rule applies to each call of a group' => sub {
  my $root = root();
  $root->child('.raider/config.yml')->touchpath->spew_utf8("permissions:\n  deny: [ 'Agent(Explore)' ]\n");
  my @events;
  my $app = slow_app(
    root      => "$root",
    sub_delay => 0.05,
    on_event  => collect( \@events ),
    script    => [
      { tool_calls => [ [ agent => { description => 'Gp', prompt => 'P1' } ],
        [ agent => { description => 'Ex', prompt => 'P2', subagent_type => 'Explore' } ],
        [ agent => { description => 'Gp2', prompt => 'P3' } ] ] },
      { text => 'R1' },
      { text => 'R3' },
      { text => 'done' },
    ],
  );
  is( '' . $app->run('go'), 'done', 'the caller answers' );
  my $texts = texts_of( $app, 'agent' );
  like( $texts->[0], qr/\AR1\nagentId: agent_1 /, 'the first runs' );
  like( $texts->[1], qr/\APermission to use agent has been denied\. Reason: denied by rule 'Agent\(Explore\)'/, 'the Explore call is denied' );
  like( $texts->[2], qr/\AR3\nagentId: agent_2 /, 'the third runs' );
  is( scalar @{ of_type( \@events, 'permission.denied', tool => 'agent' ) }, 1, 'one permission.denied' );
};

subtest 'a PreToolUse hook decides per call of a group' => sub {
  my $home = Path::Tiny->tempdir;
  push @roots, $home;
  local $ENV{HOME} = $home->realpath->stringify;
  my $root = root();
  $root->child('CLAUDE.md')->spew_utf8("Project.\n");
  my $hook = $root->child('hooks/gate');
  $hook->touchpath->spew_raw( "#!/bin/sh\n"
    .q{input=$(cat); case "$input" in *BLOCK-ME*) printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"not this one"}}';; esac}
    ."\n" );
  $hook->chmod(0755);
  $root->child('.claude/settings.json')->touchpath->spew_raw( JSON::MaybeXS->new( canonical => 1 )->encode( { hooks => {
    PreToolUse => [ { matcher => 'Agent', hooks => [ { type => 'command', command => '${CLAUDE_PROJECT_DIR}/hooks/gate' } ] } ],
  } } ) );
  my $app = slow_app(
    root            => "$root",
    sub_delay       => 0.05,
    permission_mode => 'bypassPermissions',
    script          => [
      { tool_calls => [ [ agent => { description => 'A', prompt => 'BLOCK-ME' } ], [ agent => { description => 'B', prompt => 'fine' } ] ] },
      { text => 'RB' },
      { text => 'done' },
    ],
  );
  is( '' . $app->run('go'), 'done', 'the caller answers' );
  my $texts = texts_of( $app, 'agent' );
  like( $texts->[0], qr/\Anot this one\z/, 'the hook denies the first, with its reason as Claude Code words it' );
  like( $texts->[1], qr/\ARB\nagentId: agent_1 /, 'the second runs' );
};

subtest 'journal replay of a session with concurrent agent calls' => sub {
  my $root = ''.root();
  my $app = slow_app(
    root      => $root,
    sub_delay => 0.1,
    script    => [
      { tool_calls => [ [ agent => { description => 'One', prompt => 'P1' } ], [ agent => { description => 'Two', prompt => 'P2' } ] ] },
      { text => 'REPORT A' },
      { text => 'REPORT B' },
      { text => 'both reported' },
    ],
  );
  my $session = $app->create_session;
  is( $app->run_prompt( 'go', session => $session )->{response}, 'both reported', 'the run completes' );
  my $id = $session->id;
  $session->release;
  undef $app;

  my $journal = mock_app( root => $root )->session_store->read($id);
  my @calls   = grep { $_->{type} eq 'tool.call' } @{ $journal->events };
  my @results = grep { $_->{type} eq 'tool.result' } @{ $journal->events };
  is( [ map { $_->{call} } @calls ], [qw( c1 c2 )], 'two tool.call' );
  is( [ sort map { $_->{call} } @results ], [qw( c1 c2 )], 'two tool.result, one per call' );
  is( $journal->unknown_calls, [], 'no call of unknown outcome' );
  is( $journal->runs->[0]{status}, 'completed', 'the run completed' );

  my $again = mock_app( root => $root, script => [ { text => 'resumed' } ] );
  my $reopened = $again->open_session($id);
  $again->replay_session($reopened);
  is( [ map { $_->{content} } @{ $again->raider->history } ], [ 'go', 'both reported' ], 'the history comes back' );
  my @tool_entries = grep { ( $_->{role} // '' ) eq 'tool' } @{ $again->raider->session_history };
  is( scalar @tool_entries, 2, 'both results in the session history' );
  like( [ map { $_->{content} } @tool_entries ], bag { item qr/agentId: agent_1/; item qr/agentId: agent_2/; end },
    'each agent\'s result once' );
  is( '' . $again->run_prompt( 'go on', session => $reopened )->{response}, 'resumed', 'the session goes on' );
};

done_testing;
