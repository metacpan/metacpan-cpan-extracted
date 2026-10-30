#!/usr/bin/env perl
# ABSTRACT: Every event type of raider's machine stream, read through --stream-json (ADR 0034 §5, k172)
use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Raider::Env qw( clear_engine_env isolate_home );
my $home;
BEGIN { $home = isolate_home() }
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use JSON::MaybeXS ();
use Path::Tiny;
use Test::Raider::Git qw( have_git git_repo );
use Test::Raider::SlowAI ();
use Langertha::Raider;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;

clear_engine_env();
delete @ENV{qw( RAIDER_HALL_SOCKET RAIDER_PACK_DIRS CLAUDE_CONFIG_DIR )};

# The raider CLI on the scripted mock model. @SCRIPT is the model's script,
# $ASK answers the permission questions, $REVIEW the plan review; $LAST is
# the application the last run built.
package My::CLI {
  use Moose;
  extends 'Langertha::Raider::CLI';
  our ( @SCRIPT, $ASK, $REVIEW, $LAST );
  has script    => ( is => 'ro', default => sub { [@SCRIPT] } );
  has delay     => ( is => 'ro', default => 0 );
  has sub_delay => ( is => 'ro', default => 0 );
  has usage     => ( is => 'ro' );
  has '+on_permission_request' => ( default => sub { $ASK } );
  has '+on_plan_review'        => ( default => sub { $REVIEW } );
  sub BUILD { $LAST = $_[0] }
  sub mock_engine { $_[0]->_engine }
  sub _build_engine { Test::Raider::SlowAI::App::_build_engine(@_) }
  sub build_subagent_engine { Test::Raider::SlowAI::App::build_subagent_engine(@_) }
  __PACKAGE__->meta->make_immutable;
}

package My::Main {
  use Moose;
  extends 'Langertha::Raider::CLI::Main';
  sub app_class { 'My::CLI' }
  __PACKAGE__->meta->make_immutable;
}

package main;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my %seen;   # every type some subtest read off a stream

# One `raider --stream-json ... -p go` over $root with the model's @script;
# returns the exit status and the events as a consumer reads them.
sub stream {
  my ( $root, $script, @argv ) = @_;
  local @My::CLI::SCRIPT = @$script;
  my ( $out, $err ) = ( '', '' );
  open my $ofh, '>', \$out or die $!;
  open my $efh, '>', \$err or die $!;
  open my $in, '<', \'' or die $!;
  my $exit = My::Main->new(
    output => Langertha::Raider::CLI::Output->new( out => $ofh, color => 0 ),
    err    => $efh,
    in     => $in,
  )->run( '-r', "$root", '-e', 'openai', '-k', 'mock', '--no-trace', '--stream-json', @argv, '-p', 'go' );
  my @events = map { $json->decode($_) } split /\n/, $out;
  $seen{ $_->{type} } = 1 for @events;
  return ( $exit, \@events, $err );
}

sub of_type { my ( $events, $type ) = @_; return grep { $_->{type} eq $type } @$events }

my @keep;
sub root { my $dir = Path::Tiny->tempdir; push @keep, $dir; return $dir->realpath }

# A project in the Claude layout with hooks in .claude/settings.json and
# their sh scripts under hooks/.
sub claude_project {
  my ( %a ) = @_;
  my $root = root();
  $root->child('.claude')->mkpath;
  $root->child('.claude/settings.json')->spew_raw( $json->encode({ hooks => $a{hooks} // {} }) );
  for my $name ( keys %{ $a{scripts} // {} } ) {
    my $f = $root->child( 'hooks', $name );
    $f->touchpath->spew_raw( "#!/bin/sh\n".$a{scripts}{$name}."\n" );
    $f->chmod(0755);
  }
  $root->child($_)->touchpath->spew_raw( $a{files}{$_} ) for keys %{ $a{files} // {} };
  return $root;
}

sub hook { my ( $cmd, %group ) = @_; return { hooks => [ { type => 'command', command => $cmd } ], %group } }

subtest 'run.started, tool.*, todo.updated, model.usage, message, run.state, run.finished' => sub {
  my $root = root();
  my ( $exit, $events ) = stream( $root, [
    { tool_calls => [ [ task_create => { subject => 'look', description => 'look around' } ] ] },
    { tool_calls => [ [ read_file => { path => 'missing.txt' } ] ] },
    { text => 'the answer', usage => { prompt_tokens => 12, completion_tokens => 3 } },
  ], '--dangerously-skip-permissions' );
  is( $exit, 0, 'exits 0' );
  my $app = $My::CLI::LAST;
  my $finished = $events->[-1];
  is( $events->[0], {
    version => 1, type => 'run.started', seq => 1, time => D(),
    engine => 'openai', model => T(),
    session => $finished->{session}{id}, run => 'r1',
    cwd => "$root", permission_mode => 'bypassPermissions',
    tools => [ map { $_->{function}{name} } @{ $app->mock_engine->requests->[0]{body}{tools} } ],
    raider_version => Langertha::Raider->VERSION,
  }, 'run.started: session, run, cwd, permission_mode, the tools in the order the model gets them, raider_version' );
  ok( ( grep { $_ eq 'read_file' } @{ $events->[0]{tools} } ), 'the tools are names' );
  like( [ of_type( $events, 'run.state' ) ], [ { state => 'running' }, { state => 'completed' } ], 'run.state running, completed' );

  like( [ of_type( $events, 'tool.call' ) ], [
    { call => 'c1', name => 'task_create', status => 'dispatched', arguments => { subject => 'look' } },
    { call => 'c2', name => 'read_file', status => 'dispatched' },
  ], 'tool.call: call, name, arguments, status dispatched' );
  like( [ of_type( $events, 'tool.result' ) ], [
    { call => 'c1', name => 'task_create', status => 'succeeded', ok => T(), size => D(), content => T(), truncated => F() },
    { call => 'c2', name => 'read_file', status => 'failed', ok => F() },
  ], 'tool.result: call, name, status, ok, size, content, truncated' );
  like( [ of_type( $events, 'todo.updated' ) ], [ { todos => [ { content => 'look', status => 'pending' } ] } ],
    'todo.updated: the whole list' );
  like( [ of_type( $events, 'model.usage' ) ], [ { purpose => 'chat', model => T(), input_tokens => 12, output_tokens => 3 } ],
    'model.usage: purpose, model, the tokens' );
  is( [ map { [ @$_{qw( role content )} ] } of_type( $events, 'message' ) ], [ [ assistant => 'the answer' ] ],
    'message: the final answer, the user\'s own input stays out' );
  like( $finished, { type => 'run.finished', status => 'completed', response => 'the answer', session => { id => T() } },
    'run.finished is the document' );
  ok( !exists $finished->{reason}, 'a completed run has no reason' );
  is( [ map { $_->{seq} } @$events ], [ 1 .. @$events ], 'seq counts every event' );
};

subtest 'run.started without a session: no session, no run' => sub {
  my ( $exit, $events ) = stream( root(), [ { text => 'hi' } ], '--dangerously-skip-permissions', '--no-session' );
  my ($started) = of_type( $events, 'run.started' );
  ok( !exists $started->{session} && !exists $started->{run}, 'neither field' );
  like( $started, { cwd => T(), permission_mode => 'bypassPermissions', tools => T(), raider_version => T() }, 'the rest is there' );
};

subtest 'permission.asked, permission.granted, permission.denied, permission.mode: each names its call' => sub {
  my @answers = ( 'once', 'once', 'no' );
  local $My::CLI::ASK = sub { { answer => shift(@answers) // 'no', reason => 'not that' } };
  local $My::CLI::REVIEW = sub { { approve => 1 } };
  my ( $exit, $events ) = stream( root(), [
    { tool_calls => [ [ enter_plan_mode => {} ] ] },
    { tool_calls => [ [ exit_plan_mode => { plan => 'the plan' } ] ] },
    { tool_calls => [ [ write_file => { path => 'a.txt', content => "a\n" } ] ] },
    { tool_calls => [ [ write_file => { path => 'b.txt', content => "b\n" } ] ] },
    { text => 'done' },
  ] );
  is( $exit, 0, 'exits 0' );
  my $perm = [ grep { $_->{type} =~ /\Apermission\./ } @$events ];
  like( $perm, [
    { type => 'permission.asked',   call => 'c1', tool => 'enter_plan_mode', mode => 'default', reason => T() },
    { type => 'permission.granted', call => 'c1', tool => 'enter_plan_mode', scope => 'once' },
    { type => 'permission.mode',    call => 'c1', from => 'default', to => 'plan', why => 'enter_plan_mode' },
    { type => 'permission.asked',   call => 'c2', tool => 'exit_plan_mode', mode => 'plan', reason => 'review of the plan' },
    { type => 'permission.mode',    call => 'c2', from => 'plan', to => 'default', why => 'exit_plan_mode' },
    { type => 'permission.asked',   call => 'c3', tool => 'write_file', suggested_rule => T() },
    { type => 'permission.granted', call => 'c3', tool => 'write_file', scope => 'once' },
    { type => 'permission.asked',   call => 'c4', tool => 'write_file' },
    { type => 'permission.denied',  call => 'c4', tool => 'write_file', by => 'user', reason => qr/not that/ },
  ], 'every permission event, in order, with the id of its tool.call' );
  my %call = map { $_->{call} => $_->{name} } of_type( $events, 'tool.call' );
  is( $call{ $_->{call} }, $_->{tool}, $_->{type}.' '.$_->{call}.': the tool.call of that id' )
    for grep { $_->{type} ne 'permission.mode' } @$perm;
};

subtest 'permission.denied without anyone to ask' => sub {
  my ( $exit, $events ) = stream( root(), [
    { tool_calls => [ [ write_file => { path => 'a.txt', content => "a\n" } ] ] },
    { text => 'done' },
  ] );
  like( [ of_type( $events, 'permission.denied' ) ], [ { call => 'c1', tool => 'write_file', by => 'noninteractive' } ],
    'by noninteractive, with the call' );
};

subtest 'hook.ran, hook.message; the tool hooks name their call' => sub {
  my $root = claude_project(
    hooks => {
      SessionStart       => [ hook('${CLAUDE_PROJECT_DIR}/hooks/start') ],
      PreToolUse         => [ hook( '${CLAUDE_PROJECT_DIR}/hooks/ok', matcher => 'Read' ) ],
      PostToolUse        => [ hook( '${CLAUDE_PROJECT_DIR}/hooks/ok', matcher => 'Read' ) ],
      PostToolUseFailure => [ hook( '${CLAUDE_PROJECT_DIR}/hooks/ok', matcher => 'Read' ) ],
    },
    scripts => {
      start => 'cat >/dev/null; echo \'{"systemMessage":"hello from the start hook"}\'',
      ok    => 'cat >/dev/null; exit 0',
    },
    files => { 'here.txt' => "here\n" },
  );
  my ( $exit, $events ) = stream( $root, [
    { tool_calls => [ [ read_file => { path => 'here.txt' } ] ] },
    { tool_calls => [ [ read_file => { path => 'gone.txt' } ] ] },
    { text => 'done' },
  ], '--dangerously-skip-permissions' );
  is( $exit, 0, 'exits 0' );
  my @ran = of_type( $events, 'hook.ran' );
  like( \@ran, [
    { hook_event => 'SessionStart', outcome => 'success', source => T(), command => T() },
    { hook_event => 'PreToolUse',  call => 'c1', outcome => 'success', matcher => 'Read' },
    { hook_event => 'PostToolUse', call => 'c1', outcome => 'success' },
    { hook_event => 'PreToolUse',  call => 'c2' },
    { hook_event => 'PostToolUseFailure', call => 'c2', outcome => 'success' },
  ], 'hook.ran: one per hook; the tool hooks carry the call' );
  ok( !exists $ran[0]{call}, 'SessionStart belongs to no call' );
  like( [ of_type( $events, 'hook.message' ) ], [ { hook_event => 'SessionStart', kind => 'system', text => 'hello from the start hook' } ],
    'hook.message: a systemMessage' );
};

subtest 'a tool the run does not offer: its tool.call gets a failed tool.result and PostToolUseFailure, no PreToolUse (k177)' => sub {
  my $root = claude_project(
    hooks => {
      PreToolUse         => [ hook('${CLAUDE_PROJECT_DIR}/hooks/ok') ],
      PostToolUseFailure => [ hook('${CLAUDE_PROJECT_DIR}/hooks/ok') ],
    },
    scripts => { ok => 'cat >/dev/null; exit 0' },
  );
  my ( $exit, $events ) = stream( $root, [
    { tool_calls => [ [ nonesuch => { x => 1 } ] ] },
    { text => 'done' },
  ], '--dangerously-skip-permissions' );
  is( $exit, 0, 'exits 0' );
  like( [ of_type( $events, 'tool.call' ) ], [ { call => 'c1', name => 'nonesuch', status => 'dispatched' } ], 'the call' );
  like( [ of_type( $events, 'tool.result' ) ], [ {
    call    => 'c1',
    name    => 'nonesuch',
    status  => 'failed',
    ok      => F(),
    content => '<tool_use_error>Error: No such tool available: nonesuch</tool_use_error>',
  } ], 'its result: failed, with the error the model gets' );
  like( [ of_type( $events, 'hook.ran' ) ], [ { hook_event => 'PostToolUseFailure', call => 'c1', outcome => 'success' } ],
    'PostToolUseFailure ran for it, PreToolUse did not' );
};

subtest 'message: also before Stop feedback' => sub {
  my $root = claude_project(
    hooks   => { Stop => [ hook('${CLAUDE_PROJECT_DIR}/hooks/stop') ] },
    scripts => { stop => 'cat >/dev/null; if [ -e "$CLAUDE_PROJECT_DIR/once" ]; then exit 0; fi; touch "$CLAUDE_PROJECT_DIR/once"; echo "check again" >&2; exit 2' },
  );
  my ( $exit, $events ) = stream( $root, [ { text => 'first' }, { text => 'second' } ], '--dangerously-skip-permissions' );
  is( [ map { $_->{content} } of_type( $events, 'message' ) ], [ 'first', 'second' ],
    'the answer the Stop hook sent back, then the final one' );
  is( $events->[-1]{response}, 'second', 'the document has the final one' );
};

subtest 'mcp.server, mcp.tools_changed; run.started has no tools while a server is not connected' => sub {
  my $script = path($FindBin::Bin)->child( 'lib', 'mcp-test-server.pl' )->realpath->stringify;
  my $config = path($home)->child( '.raider', 'config.yml' );
  $config->touchpath->spew_utf8(<<"YAML");
mcp:
  t:
    command: "$^X"
    args: [ "$script", "rich" ]
YAML
  my ( $exit, $events ) = stream( root(), [
    { tool_calls => [ [ 'mcp__t__bump' => {} ] ] },
    { text => 'done' },
  ], '--dangerously-skip-permissions' );
  $My::CLI::LAST->shutdown_mcp;
  $config->remove;
  is( $exit, 0, 'exits 0' );
  my ($started) = of_type( $events, 'run.started' );
  ok( !exists $started->{tools}, 'run.started: no tools -- the server starts with the first raid' );
  like( [ of_type( $events, 'mcp.server' ) ], [
    { name => 't', scope => 'raider-home', transport => 'stdio', status => 'starting' },
    { name => 't', status => 'connected', tools => D() },
  ], 'mcp.server: starting, connected' );
  like( [ of_type( $events, 'mcp.tools_changed' ) ], [ { name => 't', scope => 'raider-home' } ], 'mcp.tools_changed' );
  ok( $started->{seq} < ( of_type( $events, 'mcp.server' ) )[0]{seq}, 'run.started still comes first' );
};

subtest 'agent.warning, agent.started, agent.finished' => sub {
  my $root = root();
  $root->child('CLAUDE.md')->spew_utf8("Project.\n");
  $root->child('.claude/skills/huge/SKILL.md')->touchpath->spew_utf8( "---\ndescription: Huge.\n---\n".( "word " x 14000 )."\n" );
  $root->child('.claude/agents/briefed.md')->touchpath->spew_utf8(
    "---\nname: briefed\ndescription: Briefed.\nbriefing:\n  skills: [ huge ]\n---\nBRIEFED-BODY\n" );
  my ( $exit, $events ) = stream( $root, [
    { tool_calls => [ [ agent => { description => 'd', prompt => 'THE-TASK', subagent_type => 'briefed' } ] ] },
    { text => 'child answer' },
    { text => 'parent answer' },
  ], '--dangerously-skip-permissions' );
  is( $exit, 0, 'exits 0' );
  like( [ grep { $_->{type} =~ /\Aagent\./ } @$events ], [
    { type => 'agent.warning',  call => 'c1', agent => 'briefed', message => qr/over 64 kB/ },
    { type => 'agent.started',  call => 'c1', agent => 'briefed', agent_id => T(), background => F(), description => 'd', session => T(), model => T() },
    { type => 'agent.finished', call => 'c1', agent => 'briefed', agent_id => T(), session => T(), status => 'completed' },
  ], 'the three agent events of the call' );
};

subtest 'worktree.entered, worktree.exited' => sub {
  skip_all 'needs git' unless have_git();
  my $repo = git_repo( 'a.txt' => "a\n" );
  my ( $exit, $events ) = stream( $repo, [
    { tool_calls => [ [ enter_worktree => { name => 'cat' } ] ] },
    { tool_calls => [ [ exit_worktree => { action => 'remove' } ] ] },
    { text => 'back' },
  ], '--dangerously-skip-permissions', '--no-session' );
  is( $exit, 0, 'exits 0' );
  my $wt = $repo->child('.raider/worktrees/cat')->stringify;
  like( [ of_type( $events, 'worktree.entered' ) ], [ { path => $wt, branch => 'worktree-cat', created => T() } ], 'worktree.entered' );
  like( [ of_type( $events, 'worktree.exited' ) ], [ { path => $wt, branch => 'worktree-cat', removed => T(), reason => 'exit_worktree' } ],
    'worktree.exited' );
};

# The types bin/raider's MACHINE OUTPUT lists; each must have come through a stream above.
my $pod = path($FindBin::Bin)->parent->child( 'bin', 'raider' )->slurp_utf8;
my ($machine) = $pod =~ /^=head2 Streams\n(.*?)^=head2 Versions/ms;
my @documented = $machine =~ /^=item C<([a-z_]+\.[a-z_.]+|message)>/mg;
is( [ sort @documented ], [ sort qw(
  run.started run.state tool.call tool.result message model.usage todo.updated
  permission.asked permission.granted permission.denied permission.mode hook.ran hook.message
  mcp.server mcp.tools_changed agent.started agent.finished agent.warning
  worktree.entered worktree.exited run.finished
) ], 'the POD lists every type of the stream' );
for my $type (@documented) {
  SKIP: {
    skip 'needs git', 1 if $type =~ /\Aworktree\./ && !have_git();
    ok( $seen{$type}, $type.': read through --stream-json' );
  }
}

done_testing;
