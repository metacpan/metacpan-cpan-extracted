#!/usr/bin/env perl
# ABSTRACT: The subagent run: own tool set, own todo list, child session, agent.* events, failure and cancel (ADR 0020 §4, k153)
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
use Scalar::Util qw( refaddr );
use Test::Raider::MockAI qw( mock_app );
use Langertha::Raider::Subagent;
use Langertha::Raider::CLI::Sessions;
use Langertha::Raider::CLI::Output;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

sub root { Path::Tiny->tempdir->realpath }

sub names { [ map { $_->name } map { @{ $_->tools } } @{ $_[0] } ] }

sub child {
  my ( $app, $agent, %o ) = @_;
  return Langertha::Raider::Subagent->new(
    app             => $app,
    agent           => $agent,
    depth           => $o{depth} // 1,
    prompt          => 'do it',
    caller_servers  => $app->_tool_servers,
    on_caller_event => sub { },
  );
}

sub agent { +{ name => 'x', description => 'x', body => 'X-BODY', tools => undef, disallowed => [], @_ } }

subtest 'the tool set: the caller\'s, filtered, without ask_user, enter_plan_mode and the worktree tools, agent only below the limit' => sub {
  my $root = root();
  $root->child('.raider/skills/notes/SKILL.md')->touchpath->spew_utf8("---\ndescription: Notes.\n---\nbody\n");
  my $app = mock_app( root => "$root", max_agent_depth => 2 );
  my @parent = @{ names( $app->_tool_servers ) };
  ok( ( grep { $_ eq 'ask_user' } @parent ), 'the caller has ask_user' );
  ok( ( grep { $_ eq 'enter_plan_mode' } @parent ), 'and enter_plan_mode' );
  ok( ( grep { $_ eq 'agent' } @parent ), 'and agent' );
  ok( ( grep { $_ eq 'enter_worktree' } @parent ) && ( grep { $_ eq 'exit_worktree' } @parent ), 'and the worktree tools' );
  my %never = map { $_ => 1 } qw( ask_user enter_plan_mode enter_worktree exit_worktree );

  my $gp = child( $app, $app->context->agent_catalog->find('general-purpose'), depth => 1 );
  is( names( $gp->tool_servers ), [ grep { !$never{$_} } @parent ],
    'all tools: every tool but ask_user, enter_plan_mode and the worktree tools, in order' );
  my $deep = child( $app, agent(), depth => 2 );
  is( names( $deep->tool_servers ), [ grep { !$never{$_} && $_ ne 'agent' && $_ ne 'send_message' } @parent ],
    'at the depth limit: no agent, no send_message' );
  is( names( child( $app, agent( tools => [qw( read_file enter_plan_mode )] ) )->tool_servers ), ['read_file'],
    'enter_plan_mode goes even when listed: only the main session enters plan mode' );

  my %parent_tool = map { $_->name => $_ } map { @{ $_->tools } } @{ $app->_tool_servers };
  my %child_tool  = map { $_->name => $_ } map { @{ $_->tools } } @{ $gp->tool_servers };
  isnt( refaddr $child_tool{$_}, refaddr $parent_tool{$_}, $_.': an instance of its own (own task list)' )
    for qw( task_create task_update task_list task_get );
  isnt( refaddr $child_tool{$_}, refaddr $parent_tool{$_}, $_.': an instance of its own (own read state)' )
    for qw( read_file write_file edit_file multi_edit );
  isnt( refaddr $child_tool{agent}, refaddr $parent_tool{agent}, 'agent: one of its own depth' );
  isnt( refaddr $child_tool{$_}, refaddr $parent_tool{$_}, $_.': an instance of its own (the caller\'s follows its working root)' )
    for qw( glob grep );
  is( refaddr $child_tool{$_}, refaddr $parent_tool{$_}, $_.': the caller\'s' ) for qw( web_fetch bash bash_output );
  is( refaddr $gp->tool_servers->[1], refaddr $app->_tool_servers->[1], 'a server whose tools all stay is reused (bash)' );
  isnt( refaddr $gp->file_read_state, refaddr $app->file_read_state, 'a read state of its own' );

  is( names( child( $app, agent( tools => [qw( read_file grep )] ) )->tool_servers ), [qw( read_file grep )],
    'tools: only those, in the caller\'s order' );
  is( names( child( $app, agent( tools => [qw( grep ask_user )] ) )->tool_servers ), ['grep'],
    'ask_user goes even when listed' );
  my $no_bash = names( child( $app, agent( disallowed => ['bash'] ) )->tool_servers );
  ok( !( grep { /\A(?:bash|bash_output|kill_shell)\z/ } @$no_bash ) && ( grep { $_ eq 'write_file' } @$no_bash ),
    'disallowed bash removes bash and its shell tools, nothing else' );
  is( names( child( $app, agent( tools => [] ) )->tool_servers ), [], 'an empty allow-list: no tools' );

  # Families (ADR 0025): a name of an agent file stands for its family.
  is( names( child( $app, agent( tools => ['todo_write'] ) )->tool_servers ),
    [qw( task_create task_update task_list task_get )], 'tools: TodoWrite brings the mounted task tools' );
  is( names( child( $app, agent( tools => ['task_list'] ) )->tool_servers ),
    [qw( task_create task_update task_list task_get )], 'tools: one task tool brings the family' );
  my $no_tasks = names( child( $app, agent( disallowed => ['todo_write'] ) )->tool_servers );
  ok( !( grep { /\Atask_|\Atodo_write\z/ } @$no_tasks ) && ( grep { $_ eq 'read_file' } @$no_tasks ),
    'disallowed TodoWrite removes the task tools' );
  is( names( child( $app, agent( tools => ['edit_file'] ) )->tool_servers ), [qw( edit_file multi_edit )],
    'tools: edit_file brings multi_edit' );
  my $no_multi = names( child( $app, agent( disallowed => ['multi_edit'] ) )->tool_servers );
  ok( !( grep { /\A(?:edit_file|multi_edit)\z/ } @$no_multi ) && ( grep { $_ eq 'write_file' } @$no_multi ),
    'disallowed multi_edit removes edit_file too' );
  is( names( child( $app, agent( tools => ['bash'] ) )->tool_servers ), [qw( bash bash_output kill_shell )],
    'tools: bash brings bash_output and kill_shell' );
  is( names( child( $app, agent( tools => ['bash_output'] ) )->tool_servers ), ['bash_output'],
    'tools: bash_output alone does not bring bash' );

  my $legacy = mock_app( root => "$root", task_tools => 0 );
  my %legacy_parent = map { $_->name => $_ } map { @{ $_->tools } } @{ $legacy->_tool_servers };
  my $legacy_child = child( $legacy, agent( tools => ['task_create'] ) );
  is( names( $legacy_child->tool_servers ), ['todo_write'], 'RAIDER_ENABLE_TASKS=0: a task tool name brings todo_write' );
  isnt( refaddr $legacy_child->tool_servers->[0]->tools->[0], refaddr $legacy_parent{todo_write},
    'todo_write: an instance of its own' );

  my $mission = $gp->mission;
  like( $mission, qr/\AYou are an agent for raider/, 'the agent body in the place of the persona' );
  unlike( $mission, qr/viking shield-maiden/, 'no persona' );
  like( $mission, qr/^  - task_create\(subject, description/m, 'tool lines from its own set' );
  unlike( $mission, qr/enter_plan_mode\(/, 'without enter_plan_mode' );
  unlike( $mission, qr/ask_user\(/, 'without ask_user' );
  like( $mission, qr/- notes: Notes\./, 'with the skill tool: the skill listing' );
  my $reader = child( $app, agent( tools => ['read_file'] ) )->mission;
  unlike( $reader, qr/- notes: Notes\./, 'without the skill tool: no skill listing' );
  like( $reader, qr/\AX-BODY\n/, 'the body' );
};

subtest 'a run: own todo list, child session, agent.* events in the caller only' => sub {
  my $root = root();
  my @events;
  my $app = mock_app(
    root     => "$root",
    on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    script   => [
      { tool_calls => [ [ task_create => { subject => 'Parent step', description => 'the caller\'s' } ] ] },
      { tool_calls => [ [ agent => { description => 'Sub task', prompt => 'CHILD-PROMPT' } ] ] },
      { tool_calls => [ [ task_create => { subject => 'Child step', description => 'the subagent\'s' } ] ] },
      { text => 'child done' },
      { text => 'all done' },
    ],
  );
  my $session = $app->create_session;
  my $outcome = $app->run_prompt( 'go', session => $session );
  is( $outcome->{status}, 'completed', 'the run completes' );
  is( $outcome->{response}, 'all done', 'the caller answers' );
  is( [ map { $_->{content} } @{ $app->todos } ], ['Parent step'], 'the caller\'s list is untouched' );
  is( [ map { $_->{result}{content}[0]{text} } grep { $_->{tool_call}{name} eq q(task_create) } @{ $app->mock_engine->results } ],
    [ 'Task #1 created successfully: Parent step', 'Task #1 created successfully: Child step' ],
    'the subagent\'s list counts from 1: a list of its own' );

  is( [ map { $_->{name} } grep { $_->{type} eq 'tool.call' } @events ], [qw( task_create agent )],
    'the caller\'s stream has its own tool calls only' );
  is( scalar( grep { $_->{type} eq 'todo.updated' } @events ), 1, 'and its own todo.updated only' );
  my ($started)  = grep { $_->{type} eq 'agent.started' } @events;
  my ($finished) = grep { $_->{type} eq 'agent.finished' } @events;
  like( $started, { call => 'c2', agent => 'general-purpose', description => 'Sub task', model => 'virtual',
    session => qr/\S/, agent_id => 'agent_1', background => F() }, 'agent.started' );
  like( $finished, { call => 'c2', agent => 'general-purpose', status => 'completed', session => $started->{session},
    agent_id => 'agent_1' }, 'agent.finished' );

  my $store = $app->session_store;
  my $child_id = $started->{session};
  isnt( $child_id, $session->id, 'a session of its own' );
  my $parent_types = [ map { $_->{type} } @{ $store->read( $session->id )->events } ];
  ok( ( grep { $_ eq 'agent.started' } @$parent_types ) && ( grep { $_ eq 'agent.finished' } @$parent_types ),
    'the caller\'s journal has agent.started and agent.finished' );
  is( scalar( grep { $_->{type} eq 'tool.call' } @{ $store->read( $session->id )->events } ), 2,
    'and not the subagent\'s tool calls' );

  my $child = $store->read($child_id);
  like( $child->created, { parent => $session->id, parent_call => 'c2', agent => 'general-purpose', depth => 1,
    agent_id => 'agent_1' }, 'session.created names parent, call, agent, depth, agent ID' );
  is( [ map { $_->{type} } @{ $child->events } ],
    [qw( session.created run.started message tool.call todo.updated tool.result message run.finished )],
    'the child journals one run' );
  my %by = map { $_->{type} => $_ } reverse @{ $child->events };
  like( $by{message}, { role => 'user', content => 'CHILD-PROMPT' }, 'the prompt' );
  like( $by{'run.finished'}, { run => 'r1', status => 'completed' }, 'run.finished' );
  is( $child->runs->[0]{response}, 'child done', 'the answer' );
  like( $by{'todo.updated'}{todos}, [ { content => 'Child step' } ], 'its own list in its journal' );

  is( $store->latest, $session->id, '--continue picks the caller, not the newer child session' );
  is( $store->parent_of($child_id), $session->id, 'parent_of' );
  is( $store->parent_of( $session->id ), undef, 'a session of its own has none' );
  my $sessions = Langertha::Raider::CLI::Sessions->new( app => $app, output => Langertha::Raider::CLI::Output->new );
  like( $sessions->summary($child_id), { parent => $session->id, agent => 'general-purpose' }, 'summary names the parent' );
  ok( !exists $sessions->summary( $session->id )->{parent}, 'the caller\'s summary does not' );
  ok( !$app->_live_subagents->{$_}, 'no live subagent left' ) for keys %{ $app->_live_subagents };
};

subtest 'read before write: the subagent has a read state of its own (ADR 0023)' => sub {
  my $root = root();
  $root->child(q(a.txt))->touchpath->spew_utf8("one\n");
  my $app = mock_app(
    root            => "$root",
    permission_mode => 'bypassPermissions',   # only the read state may stop the edit
    script          => [
      { tool_calls => [ [ read_file => { path => 'a.txt' } ] ] },
      { tool_calls => [ [ agent => { description => 'd', prompt => 'edit a.txt' } ] ] },
      { tool_calls => [ [ edit_file => { path => 'a.txt', old_string => 'one', new_string => 'two too' } ] ] },
      { tool_calls => [ [ read_file => { path => 'a.txt' } ] ] },
      { tool_calls => [ [ edit_file => { path => 'a.txt', old_string => 'one', new_string => 'two too' } ] ] },
      { text => 'child done' },
      { tool_calls => [ [ edit_file => { path => 'a.txt', old_string => 'two', new_string => 'three' } ] ] },
      { text => 'all done' },
    ],
  );
  is( '' . $app->run('go'), 'all done', 'runs' );
  my @edits = grep { $_->{tool_call}{name} eq q(edit_file) } @{ $app->mock_engine->results };
  is( scalar @edits, 3, 'three edits' );
  ok( $edits[0]{result}{isError}, 'the subagent\'s edit before its own read is refused' );
  like( $edits[0]{result}{content}[0]{text}, qr/File has not been read yet/, 'with Claude Code\'s words' );
  ok( !$edits[1]{result}{isError}, 'after its own read it edits' );
  ok( $edits[2]{result}{isError}, 'the caller\'s read does not cover what the subagent changed since' );
  like( $edits[2]{result}{content}[0]{text}, qr/modified since read/, 'the caller is told to read again' );
  is( $root->child('a.txt')->slurp_utf8, "two too\n", 'the file has the subagent\'s edit only' );
};

subtest 'no caller session: no child session, events still' => sub {
  my @events;
  my $app = mock_app(
    root     => ''.root(),
    on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    script   => [ { tool_calls => [ [ agent => { description => 'd', prompt => 'p' } ] ] }, { text => 'c' }, { text => 'p' } ],
  );
  is( '' . $app->run('go'), 'p', 'runs' );
  my ($started) = grep { $_->{type} eq 'agent.started' } @events;
  ok( $started && !exists $started->{session}, 'agent.started without session' );
  is( [ $app->session_store->ids ], [], 'nothing written' );
};

subtest 'a failing subagent is an error result with the reason; the caller goes on' => sub {
  my @events;
  my $app = mock_app(
    root     => ''.root(),
    on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    script   => [
      { tool_calls => [ [ agent => { description => 'd', prompt => 'p' } ] ] },
      { error => [ 503, 'overloaded' ] },
      { text => 'went on' },
    ],
  );
  my $session = $app->create_session;
  my $outcome = $app->run_prompt( 'go', session => $session );
  is( $outcome->{response}, 'went on', 'the caller answers' );
  my $r = $app->mock_engine->results->[-1];
  ok( $r->{result}{isError}, 'the agent call failed' );
  like( $r->{result}{content}[0]{text}, qr/\AAgent 'general-purpose' \(agent_1\) failed: .*503/s,
    'with the agent ID and the reason (ADR 0027 section 2)' );
  my ($finished) = grep { $_->{type} eq 'agent.finished' } @events;
  is( $finished->{status}, 'failed', 'agent.finished failed' );
  my $child = $app->session_store->read( $finished->{session} );
  like( $child->runs->[0]{finished}, { status => 'failed', error => qr/503/ }, 'the child journal says why' );
};

{
  package Test::Raider::Subagent::NoEngine;
  use Moose;
  extends 'Test::Raider::MockAI::App';
  sub build_subagent_engine { die "no engine here\n" }
  __PACKAGE__->meta->make_immutable;
}

subtest 'an engine that cannot be built fails the call, not the caller' => sub {
  my @events;
  my $app = Test::Raider::Subagent::NoEngine->new(
    root => ''.root(), engine_name => 'openai', api_key => 'mock',
    on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    script => [ { tool_calls => [ [ agent => { description => 'd', prompt => 'p' } ] ] }, { text => 'ok' } ],
  );
  is( '' . $app->run('go'), 'ok', 'the caller answers' );
  is( $app->mock_engine->results->[-1]{result}{content}[0]{text}, "Agent 'general-purpose' (agent_1) failed: no engine here",
    'the reason' );
  my ($started) = grep { $_->{type} eq 'agent.started' } @events;
  ok( $started && !exists $started->{model}, 'agent.started without a model' );
};

{
  package Test::Raider::Subagent::CancelEngine;
  use Moose;
  extends 'Test::Raider::MockAI::SubEngine';
  has app => ( is => 'ro', weak_ref => 1 );
  sub virtual_reply { my $self = shift; $self->app->cancel_run; return $self->SUPER::virtual_reply(@_) }
  __PACKAGE__->meta->make_immutable;
}
{
  package Test::Raider::Subagent::CancelApp;
  use Moose;
  extends 'Test::Raider::MockAI::App';
  sub build_subagent_engine {
    my ( $self, %o ) = @_;
    return Test::Raider::Subagent::CancelEngine->new( main => $self->_engine, app => $self,
      langfuse_enabled => 0, mcp_servers => $o{mcp_servers} );
  }
  __PACKAGE__->meta->make_immutable;
}

subtest 'cancelling the run cancels the subagent' => sub {
  my @events;
  my $app = Test::Raider::Subagent::CancelApp->new(
    root => ''.root(), engine_name => 'openai', api_key => 'mock',
    permission_mode => 'bypassPermissions',   # only the cancel may stop the write
    on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    script => [
      { tool_calls => [ [ agent => { description => 'd', prompt => 'p' } ] ] },
      { tool_calls => [ [ write_file => { path => 'never.txt', content => 'x' } ] ] },
      { text => 'not reached' },
    ],
  );
  my $session = $app->create_session;
  my $outcome = $app->run_prompt( 'go', session => $session );
  is( $outcome->{status}, 'cancelled', 'the run ends cancelled' );
  ok( !-e path( $app->root, 'never.txt' ), 'the subagent ran no tool after the cancel' );
  my ($finished) = grep { $_->{type} eq 'agent.finished' } @events;
  is( $finished->{status}, 'cancelled', 'agent.finished cancelled' );
  my ($result) = grep { $_->{type} eq 'tool.result' && $_->{name} eq 'agent' } @events;
  is( $result->{status}, 'cancelled', 'the agent call counts as cut off' );
  like( $app->session_store->read( $finished->{session} )->runs->[0]{finished}, { status => 'cancelled' },
    'the child journal ends cancelled' );
  is( scalar( @{ $app->mock_engine->requests } ), 2, 'nothing asked the model after the cancel' );
  is( [ grep { defined } values %{ $app->_live_subagents } ], [], 'no live subagent left' );
};

subtest 'an unknown subagent_type in a run starts nothing' => sub {
  my @events;
  my $app = mock_app(
    root     => ''.root(),
    on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    script   => [ { tool_calls => [ [ agent => { description => 'd', prompt => 'p', subagent_type => 'nope' } ] ] }, { text => 'ok' } ],
  );
  is( '' . $app->run('go'), 'ok', 'the caller answers' );
  like( $app->mock_engine->results->[-1]{result}{content}[0]{text}, qr/\AUnknown agent type 'nope'\. Available agents: general-purpose, Explore, Plan\.\z/,
    'names the available agents' );
  is( [ grep { $_->{type} =~ /\Aagent\./ } @events ], [], 'no agent.* event' );
  is( scalar @{ $app->mock_engine->requests }, 2, 'no subagent request' );
};

subtest 'nested: a grandchild journals under the child session' => sub {
  my @events;
  my $app = mock_app(
    root            => ''.root(),
    max_agent_depth => 2,
    on_event        => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    script          => [
      { tool_calls => [ [ agent => { description => 'outer', prompt => 'OUTER' } ] ] },
      { tool_calls => [ [ agent => { description => 'inner', prompt => 'INNER' } ] ] },
      { text => 'inner done' },
      { text => 'outer done' },
      { text => 'all done' },
    ],
  );
  my $session = $app->create_session;
  is( $app->run_prompt( 'go', session => $session )->{response}, 'all done', 'runs' );
  my @started = grep { $_->{type} eq 'agent.started' } @events;
  is( scalar @started, 1, 'the caller sees its own subagent only' );
  my $store = $app->session_store;
  my $child = $store->read( $started[0]{session} );
  my ($inner) = grep { $_->{type} eq 'agent.started' } @{ $child->events };
  like( $inner, { call => 'c1', description => 'inner', session => qr/\S/ }, 'the child journals the grandchild start' );
  like( $store->read( $inner->{session} )->created, { parent => $started[0]{session}, parent_call => 'c1', depth => 2 },
    'the grandchild session hangs below the child' );
  is( $store->latest, $session->id, 'latest is still the caller' );
};

done_testing;
