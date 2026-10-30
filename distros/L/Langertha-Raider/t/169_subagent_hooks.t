#!/usr/bin/env perl
# ABSTRACT: Claude Code hooks around and inside subagents: SubagentStart/SubagentStop, agent_id and agent_type, where the reports go (ADR 0020, ADR 0022, k153)
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
use JSON::MaybeXS ();
use Path::Tiny;
use Test::Raider::MockAI qw( mock_app );

delete @ENV{qw( RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

# A Claude project (CLAUDE.md, .claude/settings.json with %hooks) with the
# agent "scribe"; hook scripts are sh files in hooks/. A hook "record EVENT"
# writes its stdin to EVENT.json in the root.
my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my @keep;

sub project {
  my ( %a ) = @_;
  my $home = Path::Tiny->tempdir;
  my $root = Path::Tiny->tempdir;
  push @keep, $home, $root;
  $ENV{HOME} = $home->realpath->stringify;
  $root = $root->realpath;
  $root->child('CLAUDE.md')->spew_utf8("Project.\n");
  $root->child('notes.txt')->spew_utf8("NOTE\n");
  $root->child('.claude/agents/scribe.md')->touchpath->spew_utf8("---\nname: scribe\ndescription: Writes notes.\n---\nSCRIBE-BODY\n");
  $root->child('.claude/settings.json')->spew_raw( $json->encode( { hooks => $a{hooks} // {} } ) );
  my %scripts = (
    record => 'cat > "$CLAUDE_PROJECT_DIR/$1.json"',
    %{ $a{scripts} // {} },
  );
  for my $name ( keys %scripts ) {
    my $f = $root->child( 'hooks', $name );
    $f->touchpath->spew_raw( "#!/bin/sh\n".$scripts{$name}."\n" );
    $f->chmod(0755);
  }
  return $root;
}

sub hook {
  my ( $cmd, @args ) = @_;
  return { type => 'command', command => '${CLAUDE_PROJECT_DIR}/hooks/'.$cmd, args => [@args] };
}

sub app_for {
  my ( $root, @script ) = @_;
  my @events;
  my $app = mock_app(
    root            => "$root",
    permission_mode => 'bypassPermissions',
    on_event        => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    script          => \@script,
  );
  return ( $app, \@events );
}

sub input_of { my ( $root, $event ) = @_; return $json->decode( $root->child( $event.'.json' )->slurp_raw ) }

my $spawn = { tool_calls => [ [ agent => { description => 'd', prompt => 'THE-TASK', subagent_type => 'scribe' } ] ] };

subtest 'with a session: agent_id is the child session, the inputs carry agent_type and the caller\'s session' => sub {
  my $root = project( hooks => {
    SubagentStart => [ { hooks => [ hook( record => 'start' ) ] } ],
    SubagentStop  => [ { hooks => [ hook( record => 'stop' ) ] } ],
    PreToolUse    => [ { matcher => 'Read', hooks => [ hook( record => 'pre' ) ] } ],
  } );
  my ( $app, $events ) = app_for( $root, $spawn,
    { tool_calls => [ [ read_file => { path => 'notes.txt' } ] ] }, { text => 'child done' }, { text => 'parent done' } );
  my $session = $app->create_session;
  is( $app->run_prompt( 'go', session => $session )->{response}, 'parent done', 'the run completes' );
  my ($started) = grep { $_->{type} eq 'agent.started' } @$events;
  my $child = $started->{session};
  ok( $child, 'a child session' );

  my $start = input_of( $root, 'start' );
  like( $start, { hook_event_name => 'SubagentStart', agent_id => $child, agent_type => 'scribe',
    session_id => $session->id, permission_mode => 'bypassPermissions' }, 'SubagentStart input' );
  my $stop = input_of( $root, 'stop' );
  like( $stop, { hook_event_name => 'SubagentStop', agent_id => $child, agent_type => 'scribe',
    session_id => $session->id, last_assistant_message => 'child done', stop_hook_active => JSON::MaybeXS->false,
    agent_transcript_path => qr/\Q$child\E/ }, 'SubagentStop input' );
  like( input_of( $root, 'pre' ), { hook_event_name => 'PreToolUse', tool_name => 'Read', agent_id => $child,
    agent_type => 'scribe', session_id => $session->id }, 'the subagent\'s PreToolUse names the agent' );

  my @caller_hooks = map { $_->{hook_event} } grep { $_->{type} eq 'hook.ran' } @$events;
  is( \@caller_hooks, [qw( SubagentStart SubagentStop )], 'the caller\'s stream: SubagentStart and SubagentStop only' );
  my $store = $app->session_store;
  is( [ map { $_->{hook_event} } grep { $_->{type} eq 'hook.ran' } @{ $store->read( $session->id )->events } ],
    [qw( SubagentStart SubagentStop )], 'and the caller\'s journal' );
  is( [ map { $_->{hook_event} } grep { $_->{type} eq 'hook.ran' } @{ $store->read($child)->events } ],
    ['PreToolUse'], 'the subagent\'s own hook runs are in its journal' );
};

subtest 'without a session: a local agent_id' => sub {
  my $root = project( hooks => { SubagentStart => [ { hooks => [ hook( record => 'start' ) ] } ] } );
  my ( $app ) = app_for( $root, $spawn, { text => 'c' }, { text => 'p' } );
  is( '' . $app->run('go'), 'p', 'runs' );
  like( input_of( $root, 'start' ), { agent_id => qr/\Alocal-agent-$$-\d+\z/, agent_type => 'scribe' }, 'agent_id' );
};

subtest 'SubagentStart continue: false fails the agent before its first request' => sub {
  my $root = project(
    hooks   => { SubagentStart => [ { hooks => [ hook('halt') ] } ] },
    scripts => { halt => q{cat >/dev/null; printf '%s' '{"continue":false,"stopReason":"no agents today"}'} },
  );
  my ( $app, $events ) = app_for( $root, $spawn, { text => 'the caller goes on' } );
  my $session = $app->create_session;
  is( $app->run_prompt( 'go', session => $session )->{response}, 'the caller goes on', 'the caller answers' );
  is( scalar @{ $app->mock_engine->requests }, 2, 'no child request' );
  my $r = $app->mock_engine->results->[-1];
  ok( $r->{result}{isError}, 'the agent call failed' );
  is( $r->{result}{content}[0]{text}, "Agent 'scribe' (agent_1) failed: a SubagentStart hook stopped it: no agents today", 'with the reason' );
  my ($finished) = grep { $_->{type} eq 'agent.finished' } @$events;
  is( $finished->{status}, 'failed', 'agent.finished failed' );
  like( [ grep { $_->{type} eq 'hook.message' } @$events ], [ { hook_event => 'SubagentStart', kind => 'stopped', text => 'no agents today' } ],
    'the stop is reported to the caller' );
  my $child = $app->session_store->read( $finished->{session} );
  is( [ grep { $_->{type} eq 'message' } @{ $child->events } ], [], 'the child journal has no prompt it was never sent' );
  like( $child->runs->[0]{finished}, { status => 'failed', error => qr/no agents today/ }, 'and says why' );
};

subtest 'continue: false in a subagent\'s tool hook cancels the subagent, not the caller' => sub {
  my $root = project(
    hooks   => { PreToolUse => [ { matcher => 'Read', hooks => [ hook('halt') ] } ] },
    scripts => { halt => q{input=$(cat); case "$input" in *'"agent_type":"scribe"'*) printf '%s' '{"continue":false,"stopReason":"enough"}';; esac} },
  );
  my ( $app, $events ) = app_for( $root, $spawn,
    { tool_calls => [ [ read_file => { path => 'notes.txt' } ] ] }, { text => 'the caller goes on' } );
  my $outcome = $app->run_prompt('go');
  is( scalar @{ $app->mock_engine->requests }, 3, 'the subagent makes no request after the stop' );
  is( $outcome->{status}, 'completed', 'the caller completes' );
  is( $outcome->{response}, 'the caller goes on', 'and answers' );
  is( $app->mock_engine->results->[-1]{result}{content}[0]{text}, "Agent 'scribe' (agent_1) was cancelled.", 'the agent was cancelled' );
};

subtest 'a subagent\'s own task list fires TaskCreated and TaskCompleted, reported to its journal' => sub {
  my $root = project(
    hooks   => {
      TaskCreated   => [ { hooks => [ hook('created') ] } ],
      TaskCompleted => [ { hooks => [ hook( record => 'completed' ) ] } ],
    },
    scripts => { created => q{input=$(cat); printf '%s' "$input" > "$CLAUDE_PROJECT_DIR/created.json"; case "$input" in *'"task_subject":"Vague"'*) echo "be specific" >&2; exit 2;; esac} },
  );
  my ( $app, $events ) = app_for( $root, $spawn,
    { tool_calls => [ [ task_create => { subject => 'Vague', description => 'x' } ] ] },
    { tool_calls => [ [ task_create => { subject => 'Write notes', description => 'short ones' } ] ] },
    { tool_calls => [ [ task_update => { taskId => '1', status => 'completed' } ] ] },
    { text => 'child done' }, { text => 'parent done' } );
  my $session = $app->create_session;
  is( $app->run_prompt( 'go', session => $session )->{response}, 'parent done', 'the run completes' );
  my ($started) = grep { $_->{type} eq 'agent.started' } @$events;
  my $child = $started->{session};

  my @results = map { [ $_->{tool_call}->name, $_->{result}{content}[0]{text}, $_->{result}{isError} ? 1 : 0 ] }
    grep { $_->{tool_call}->name =~ /\Atask_/ } @{ $app->mock_engine->results };
  is( \@results, [
    [ task_create => 'TaskCreated hook error: be specific', 1 ],
    [ task_create => 'Task #1 created successfully: Write notes', 0 ],
    [ task_update => 'Updated task #1 status', 0 ],
  ], 'the block refuses the first creation, the rest goes on' );
  like( input_of( $root, 'created' ), { hook_event_name => 'TaskCreated', task_subject => 'Write notes',
    agent_id => $child, agent_type => 'scribe', permission_mode => 'bypassPermissions', session_id => $session->id },
    'TaskCreated carries the subagent\'s fields' );
  like( input_of( $root, 'completed' ), { hook_event_name => 'TaskCompleted', task_id => '1', agent_type => 'scribe' },
    'so does TaskCompleted' );
  is( [ grep { $_->{type} eq 'hook.ran' } @$events ], [], 'nothing in the caller\'s stream' );
  is( [ map { [ $_->{hook_event}, $_->{outcome} ] } grep { $_->{type} eq 'hook.ran' } @{ $app->session_store->read($child)->events } ],
    [ [ TaskCreated => 'block' ], [ TaskCreated => 'success' ], [ TaskCompleted => 'success' ] ], 'the subagent\'s journal' );
  is( $app->todos, [], 'the caller\'s list is untouched' );
};

subtest 'SubagentStop that never lets go: at most stop_hook_limit continuations' => sub {
  my $root = project(
    hooks   => { SubagentStop => [ { hooks => [ hook('nag') ] } ] },
    scripts => { nag => q{cat >/dev/null; echo "again" >&2; exit 2} },
  );
  my $limit = 8;
  my ( $app, $events ) = app_for( $root, $spawn, ( map { { text => 'answer '.$_ } } 0 .. $limit ), { text => 'parent' } );
  is( '' . $app->run('go'), 'parent', 'the caller answers' );
  is( scalar @{ $app->mock_engine->requests }, 1 + ( $limit + 1 ) + 1, 'the subagent went on '.$limit.' times' );
  like( $app->mock_engine->results->[-1]{result}{content}[0]{text}, qr/\Aanswer $limit\nagentId: agent_1 /,
    'the caller gets the last answer' );
  like( [ grep { $_->{type} eq 'hook.message' && $_->{kind} eq 'error' } @$events ],
    [ { hook_event => 'SubagentStop', text => qr/kept agent 'scribe' going 8 times in a row/ } ], 'the cut is reported' );
};

done_testing;
