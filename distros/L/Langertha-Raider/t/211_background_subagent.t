#!/usr/bin/env perl
# ABSTRACT: Agent IDs, the result trailer, background subagents and their notifications (ADR 0027 §1–§4, k161)
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
use Path::Tiny;
use Test::Raider::MockAI qw( mock_app );
use Test::Raider::SlowAI qw( slow_app );

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

# Each root lives as long as the test does.
my @roots;
sub root { my $dir = Path::Tiny->tempdir; push @roots, $dir; $dir->realpath }

sub collect { my ( $list ) = @_; return sub { my ( $type, %p ) = @_; push @$list, { type => $type, %p } } }

sub text_of { my ( $m ) = @_; my $c = $m->{content}; ref $c ? join( '', map { $_->{text} // '' } @$c ) : $c // '' }

# The tool result of the call named $name in the order they came back.
sub results_of { my ( $app, $name ) = @_; [ grep { $_->{tool_call}->name eq $name } @{ $app->mock_engine->results } ] }

# The text of a user message without the situation line every raid's first message gets.
sub prompt_of { my $t = text_of( $_[0] ); $t =~ s/\A\[situation\][^\n]*\n\n//; $t }

subtest 'foreground: the report with agent ID and usage (ADR 0027 section 2)' => sub {
  my $app = slow_app(
    root   => ''.root(),
    usage  => { prompt_tokens => 100, completion_tokens => 20 },
    script => [
      { tool_calls => [ [ agent => { description => 'Look', prompt => 'P' } ] ] },
      { tool_calls => [ [ list_files => { path => '.' } ] ] },
      { tool_calls => [ [ glob => { pattern => '*' } ] ] },
      { text => 'the <report>' },
      { tool_calls => [ [ agent => { description => 'Again', prompt => 'Q' } ] ] },
      { text => 'second' },
      { text => 'done' },
    ],
  );
  is( '' . $app->run('go'), 'done', 'the caller answers' );
  my @agent = map { $_->{result}{content}[0]{text} } @{ results_of( $app, 'agent' ) };
  like( $agent[0], qr{\Athe <report>\nagentId: agent_1 \(use send_message with to: 'agent_1' to continue this agent\)\n<usage>subagent_tokens: 120\ntool_uses: 2\nduration_ms: \d+</usage>\z},
    'report, agentId line, usage: tokens of the last response, the run\'s tool calls' );
  like( $agent[1], qr{\Asecond\nagentId: agent_2 .*\ntool_uses: 0\n}s, 'the next agent is agent_2, with its own count' );
  my $entry = $app->tasks->get('agent_1');
  like( $entry, { kind => 'agent', status => 'completed', description => 'Look', tool_use_id => 'c1', recipient => 'main',
    report => 'the <report>', background => F() }, 'the registry keeps the finished agent' );
  is( $entry->{usage}, [ subagent_tokens => 120, tool_uses => 2, duration_ms => match qr/^\d+$/ ], 'and its usage' );
};

subtest 'background: launched at once, runs on the loop, its notification goes in front of the next request' => sub {
  my @events;
  my $app = slow_app(
    root     => ''.root(),
    delay    => 0.05,
    on_event => collect( \@events ),
    script   => [
      { tool_calls => [ [ agent => { description => 'Find it', prompt => 'BG-PROMPT', run_in_background => \1 } ] ] },
      # the background agent's request is answered while the main run's second one waits
      { text => 'BG REPORT: a < b & c' },
      { tool_calls => [ [ todo_write => { todos => [ { content => 'step', status => 'in_progress' } ] } ] ] },
      { text => 'main done' },
    ],
  );
  my $session = $app->create_session;
  my $outcome = $app->run_prompt( 'go', session => $session );
  is( $outcome->{response}, 'main done', 'the run answers' );

  my ($launch) = map { $_->{result}{content}[0]{text} } @{ results_of( $app, 'agent' ) };
  is( $launch, join( "\n",
    'Async agent launched successfully.',
    "agentId: agent_1 (use send_message with to: 'agent_1' to continue this agent)",
    "The agent is working in the background. You will be notified automatically when it completes. You know nothing about its results until that notification arrives \x{2014} do not report, assume, or predict them; continue other work or respond to the user in the meantime.",
    "Do not duplicate this agent's work \x{2014} avoid working with the same files or topics it is using.",
  ), 'the launch text, not an error' );
  ok( !results_of( $app, 'agent' )->[0]{result}{isError}, 'no error' );

  my $requests = $app->mock_engine->requests;
  is( scalar @$requests, 4, 'four requests: main, agent, main, main' );
  is( prompt_of( ( grep { $_->{role} eq 'user' } @{ $requests->[1]{messages} } )[0] ), 'BG-PROMPT', 'the agent got its prompt' );
  my @last = @{ $requests->[3]{messages} };
  is( $last[-1]{role}, 'user', 'the last request ends with a user message' );
  is( $last[-2]{role}, 'tool', 'after the tool results of the turn' );
  is( text_of( $last[-1] ), join( "\n",
    '<task-notification>',
    '<task-id>agent_1</task-id>',
    '<tool-use-id>c1</tool-use-id>',
    '<status>completed</status>',
    '<summary>Agent "Find it" finished</summary>',
    '<result>BG REPORT: a &lt; b &amp; c</result>',
  )."\n".'<usage><subagent_tokens>0</subagent_tokens><tool_uses>0</tool_uses><duration_ms>'
    .( text_of( $last[-1] ) =~ /<duration_ms>(\d+)</ )[0].'</duration_ms></usage>'."\n</task-notification>",
    'the notification, escaped, in Claude Code\'s form' );
  ok( !( grep { text_of($_) =~ /task-notification/ } @{ $requests->[2]{messages} } ), 'not before it was due' );

  my ($started)  = grep { $_->{type} eq 'agent.started' } @events;
  my ($finished) = grep { $_->{type} eq 'agent.finished' } @events;
  like( $started, { agent_id => 'agent_1', background => T(), call => 'c1', description => 'Find it' }, 'agent.started' );
  like( $finished, { agent_id => 'agent_1', status => 'completed' }, 'agent.finished' );

  my @journal = @{ $app->session_store->read( $session->id )->events };
  my ($note) = grep { $_->{type} eq 'message' && $_->{notification} } @journal;
  like( $note, { role => 'user', run => 'r1', content => qr/\A<task-notification>\n<task-id>agent_1</ }, 'journaled as a user message with notification 1' );
  ok( ( grep { $_->{type} eq 'agent.finished' && ( $_->{run} // '' ) eq 'r1' } @journal ), 'agent.finished in the run' );
  is( $app->tasks->get('agent_1')->{status}, 'completed', 'the registry says completed' );
  is( $app->notifications_pending, 0, 'nothing left to deliver' );
};

subtest 'a non-interactive run waits for its background agents (wait_background)' => sub {
  my @events;
  my $app = mock_app(
    root     => ''.root(),
    on_event => collect( \@events ),
    script   => [
      { tool_calls => [ [ agent => { description => 'Later', prompt => 'BG', run_in_background => \1 } ] ] },
      { text => 'first answer' },
      { text => 'BG REPORT' },
      { text => 'final answer' },
    ],
  );
  my $session = $app->create_session;
  my $outcome = $app->run_prompt( 'go', session => $session, wait_background => 1 );
  is( $outcome->{status}, 'completed', 'completed' );
  is( $outcome->{response}, 'final answer', 'the answer after the notification' );
  like( text_of( $app->mock_engine->requests->[3]{messages}[-1] ), qr{<task-id>agent_1</task-id>.*<result>BG REPORT</result>}s,
    'the notification is the next message' );
  my $run = $app->session_store->read( $session->id )->runs->[0];
  is( [ $run->{prompt}, $run->{response}, $run->{status} ], [ 'go', 'final answer', 'completed' ], 'one run in the journal' );
  is( [ map { [ $_->{role}, $_->{notification} ? 1 : 0 ] } grep { $_->{type} eq 'message' } @{ $app->session_store->read( $session->id )->events } ],
    [ [ user => 0 ], [ assistant => 0 ], [ user => 1 ], [ assistant => 0 ] ], 'go, first answer, the notification, final answer' );
  is( $app->background_running, 0, 'nothing runs any more' );
};

subtest 'without waiting: the run ends, the agent ends between runs and journals into the session' => sub {
  my @events;
  my $app = mock_app(
    root     => ''.root(),
    on_event => collect( \@events ),
    script   => [
      { tool_calls => [ [ agent => { description => 'Later', prompt => 'BG', run_in_background => \1 } ] ] },
      { text => 'first answer' },
      { text => 'BG REPORT' },
    ],
  );
  my $session = $app->create_session;
  is( $app->run_prompt( 'go', session => $session )->{response}, 'first answer', 'the run does not wait' );
  is( $app->background_running, 1, 'the agent still runs' );
  is( $app->wait_for_notifications, 1, 'the loop runs it to its end' );
  my ($item) = $app->take_notifications;
  is( $item->{label}, 'background agent agent_1 finished', 'the line the REPL shows' );
  like( $item->{text}, qr{<result>BG REPORT</result>}, 'the notification' );
  my @journal = @{ $app->session_store->read( $session->id )->events };
  my ($finished) = grep { $_->{type} eq 'agent.finished' } @journal;
  ok( $finished && !exists $finished->{run}, 'agent.finished appended to the session outside a run' );
  is( $journal[-1]{type}, 'agent.finished', 'after the run' );
};

subtest 'a subagent waits for its own background agents before it answers' => sub {
  my @events;
  my $app = mock_app(
    root            => ''.root(),
    max_agent_depth => 2,
    on_event        => collect( \@events ),
    script          => [
      { tool_calls => [ [ agent => { description => 'outer', prompt => 'OUTER' } ] ] },
      { tool_calls => [ [ agent => { description => 'inner', prompt => 'INNER', run_in_background => \1 } ] ] },
      { text => 'outer first' },
      { text => 'INNER REPORT' },
      { text => 'outer final' },
      { text => 'all done' },
    ],
  );
  my $session = $app->create_session;
  is( $app->run_prompt( 'go', session => $session )->{response}, 'all done', 'the caller answers' );
  like( results_of( $app, 'agent' )->[-1]{result}{content}[0]{text}, qr/\Aouter final\nagentId: agent_1 /,
    'the outer agent answers after the inner one\'s notification' );
  my $requests = $app->mock_engine->requests;
  like( text_of( $requests->[4]{messages}[-1] ), qr{<task-id>agent_2</task-id>\n<tool-use-id>c1</tool-use-id>.*<result>INNER REPORT</result>}s,
    'the outer agent got the notification of agent_2' );
  like( $app->tasks->get('agent_2'), { recipient => 'agent_1', background => T(), status => 'completed' }, 'agent_2 belongs to agent_1' );
  my ($outer) = grep { $_->{type} eq 'agent.started' } @events;
  my @child = @{ $app->session_store->read( $outer->{session} )->events };
  ok( ( grep { $_->{type} eq 'message' && $_->{notification} } @child ), 'the outer journal has the notification' );
  ok( ( grep { $_->{type} eq 'agent.finished' && $_->{agent_id} eq 'agent_2' } @child ), 'and agent_2\'s end' );
  like( $app->session_store->created_of( $outer->{session} ), { agent_id => 'agent_1' }, 'session.created has the agent ID' );
};

subtest 'a background agent cannot ask: a call its policy asks about is refused' => sub {
  my @asked;
  my $root = root();
  my $app = mock_app(
    root                  => "$root",
    permission_mode       => 'default',
    on_permission_request => sub { push @asked, $_[0]; return { answer => 'once' } },
    script                => [
      { tool_calls => [ [ agent => { description => 'w', prompt => 'write', run_in_background => \1 } ] ] },
      { text => 'started' },
      { tool_calls => [ [ write_file => { path => 'bg.txt', content => 'x' } ] ] },
      { text => 'could not' },
      { text => 'ok' },
    ],
  );
  $app->run_prompt( 'go', wait_background => 1 );
  is( \@asked, [], 'nobody was asked' );
  ok( !-e $root->child('bg.txt'), 'nothing written' );
  my ($write) = @{ results_of( $app, 'write_file' ) };
  ok( $write->{result}{isError}, 'the call was refused' );
  like( $write->{result}{content}[0]{text}, qr/nobody can approve it: this agent runs in the background\./, 'saying why' );
};

subtest 'the first Ctrl-C leaves background agents running; stop_background ends them' => sub {
  my @events;
  my $app;
  $app = slow_app(
    root      => ''.root(),
    delay     => 0.05,
    sub_delay => 30,
    # Ctrl-C once the background agent has started, while the main run waits for its model.
    on_event  => sub {
      collect( \@events )->(@_);
      $app->cancel_run if $_[0] eq 'agent.started';
    },
    script    => [
      { tool_calls => [ [ agent => { description => 'Slow', prompt => 'BG', run_in_background => \1 } ] ] },
      { tool_calls => [ [ list_files => { path => '.' } ] ] },
      { text => 'never' },
    ],
  );
  my $session = $app->create_session;
  my $outcome = $app->run_prompt( 'go', session => $session );
  is( $outcome->{status}, 'cancelled', 'the run is cancelled' );
  is( $app->background_running, 1, 'the background agent still runs' );
  is( $app->tasks->get('agent_1')->{status}, 'running', 'running in the registry' );
  my $t0 = time;
  is( $app->stop_background, 1, 'leaving stops it' );
  ok( time - $t0 < 10, 'without waiting for its model' );
  is( $app->tasks->get('agent_1')->{status}, 'killed', 'killed' );
  my ($item) = $app->take_notifications;
  like( $item->{text}, qr{<status>killed</status>\n<summary>Agent "Slow" was stopped</summary>}, 'a killed notification' );
  is( $item->{label}, 'background agent agent_1 was stopped', 'its line' );
  my ($finished) = grep { $_->{type} eq 'agent.finished' } @events;
  is( $finished->{status}, 'cancelled', 'agent.finished cancelled' );
};

subtest 'failed: the notification says why, without a result' => sub {
  my $app = mock_app(
    root   => ''.root(),
    script => [
      { tool_calls => [ [ agent => { description => 'Boom', prompt => 'BG', run_in_background => \1 } ] ] },
      { text => 'first' },
      { error => [ 503, 'overloaded' ] },
      { text => 'final' },
    ],
  );
  is( $app->run_prompt( 'go', wait_background => 1 )->{response}, 'final', 'the run goes on' );
  my $note = $app->mock_engine->requests->[3]{messages}[-1];
  like( text_of($note), qr{<status>failed</status>\n<summary>Agent "Boom" failed: .*503.*</summary>\n<usage>}s, 'failed, with the reason' );
  unlike( text_of($note), qr/<result>/, 'no result' );
};

subtest 'one-shot agents: no agentId line' => sub {
  my $app = mock_app(
    root   => ''.root(),
    script => [ { tool_calls => [ [ agent => { description => 'x', prompt => 'y', subagent_type => 'Explore' } ] ] }, { text => 'found' }, { text => 'ok' } ],
  );
  skip_all 'no Explore built-in in this tree' unless $app->context->agent_catalog->find('Explore');
  $app->run('go');
  like( results_of( $app, 'agent' )->[0]{result}{content}[0]{text}, qr/\Afound\n<usage>subagent_tokens: /, 'report and usage only' );
};

sub rule_texts { [ map { $_->text } @{ $_[0]->run_rules } ] }

subtest 'run rules: a background agent keeps its own copy, a foreground one shares the run\'s (ADR 0027, ADR 0030)' => sub {
  my $app = slow_app(
    root      => ''.root(),
    sub_delay => 30,
    script    => [
      { tool_calls => [ [ agent => { description => 'Long', prompt => 'BG', run_in_background => \1 } ] ] },
      { text => 'started' },
    ],
  );
  my $out = $app->run_prompt( 'go', allow_rules => ['Bash(echo:*)'], allow_source => '/one allowed-tools' );
  is( $out->{response}, 'started', 'the run answers' );
  my $policy = $app->tasks->get('agent_1')->{subagent}->permissions;
  is( rule_texts( $app->permissions ), [], 'the run ended: its rules are gone from the session' );
  is( rule_texts($policy), ['Bash(echo:*)'], 'the background agent still has them' );
  $app->begin_run( allow_rules => ['Read'], allow_source => '/two allowed-tools' );
  is( rule_texts( $app->permissions ), ['Read'], 'a later run has its own' );
  is( rule_texts($policy), ['Bash(echo:*)'], 'they do not reach the background agent' );
  $app->end_run('completed');
  $app->stop_background;

  # While the foreground agent runs (its agent.started): its policy and the
  # run's share one list.
  my $fg = slow_app(
    root   => ''.root(),
    script => [
      { tool_calls => [ [ agent => { description => 'Now', prompt => 'FG' } ] ] },
      { text => 'sub done' },
      { text => 'done' },
    ],
  );
  my ( $shared, $seen );
  my $run = $fg->run_prompt( 'go', allow_rules => ['Bash(ls:*)'], allow_source => '/fg allowed-tools',
    on_event => sub {
      my ( $type, %p ) = @_;
      return unless $type eq 'agent.started';
      my $policy = $fg->tasks->get( $p{agent_id} )->{subagent}->permissions;
      $shared = $policy->run_rules == $fg->permissions->run_rules ? 1 : 0;
      $seen   = rule_texts($policy);
    } );
  is( $run->{response}, 'done', 'the foreground run answers' );
  is( $shared, 1, 'the foreground agent shares the run\'s list' );
  is( $seen, ['Bash(ls:*)'], 'and has its rule' );
  is( rule_texts( $fg->tasks->get('agent_1')->{subagent}->permissions ), [], 'cleared with the run' );
};

done_testing;
