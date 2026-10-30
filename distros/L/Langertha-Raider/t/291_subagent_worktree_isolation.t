#!/usr/bin/env perl
# ABSTRACT: Subagents in a worktree of their own -- isolation: "worktree" (ADR 0032 §2, §3; ADR 0027 §7; k168)
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
use Test::Raider::Git qw( have_git git_repo git_in );
use Test::Raider::MockAI qw( mock_app );
use Test::Raider::SlowAI qw( slow_app );
use Langertha::Raider::Worktree;

plan skip_all => 'needs git' unless have_git();

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

my @dirs;
sub tmpdir { my $d = Path::Tiny->tempdir; push @dirs, $d; $d->realpath }

sub collect { my ( $list ) = @_; return sub { my ( $type, %p ) = @_; push @$list, { type => $type, %p } } }

sub text_of { my ( $m ) = @_; my $c = $m->{content}; ref $c ? join( '', map { $_->{text} // '' } @$c ) : $c // '' }

# The results of the calls named $name, in the order they came back: { text, error }.
sub results_of {
  my ( $app, $name ) = @_;
  return [ map { { text => $_->{result}{content}[0]{text}, error => $_->{result}{isError} ? 1 : 0 } }
    grep { $_->{tool_call}->name eq $name } @{ $app->mock_engine->results } ];
}

sub app_in {
  my ( $root, @script ) = @_;
  my %o = ref $script[0] eq 'HASH' && !exists $script[0]{tool_calls} && !exists $script[0]{text} ? %{ shift @script } : ();
  return mock_app( root => "$root", permission_mode => 'bypassPermissions', script => \@script, %o );
}

my $git = Langertha::Raider::Worktree->new;

subtest 'no changes: the worktree and its branch are removed, the result names none' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my @events;
  my $app = app_in( $repo, { on_event => collect( \@events ) },
    { tool_calls => [ [ agent => { description => 'Look', prompt => 'Look around.', isolation => 'worktree' } ] ] },
    { tool_calls => [ [ bash => { command => 'pwd; git worktree list --porcelain' } ] ] },
    { tool_calls => [ [ read_file => { path => 'a.txt' } ] ] },
    { text => 'nothing to change' },
    { text => 'fine' },
  );
  is( '' . $app->run('go'), 'fine', 'the caller answers' );
  my $wt = $repo->child('.raider/worktrees/agent-1');
  my ($bash) = @{ results_of( $app, 'bash' ) };
  like( $bash->{text}, qr/\A\Q$wt\E\n/, 'bash starts in the worktree' );
  like( $bash->{text}, qr/^worktree \Q$wt\E\nHEAD [0-9a-f]+\nbranch refs\/heads\/worktree-agent-1\nlocked raider agent agent_1$/m,
    'the worktree is locked while the agent runs, with the agent ID as reason' );
  my ($read) = @{ results_of( $app, 'read_file' ) };
  like( $read->{text}, qr/a/, 'a relative path reads the copy' );
  my ($agent) = @{ results_of( $app, 'agent' ) };
  like( $agent->{text}, qr{\Anothing to change\nagentId: agent_1 .*\n<usage>.*</usage>\z}s, 'the usual result, no worktree lines' );
  ok( !$wt->exists, 'the worktree is removed' );
  ok( !$git->branch_exists( "$repo", 'worktree-agent-1' ), 'and its branch' );

  my ($started)  = grep { $_->{type} eq 'agent.started' } @events;
  my ($finished) = grep { $_->{type} eq 'agent.finished' } @events;
  like( $started, { agent_id => 'agent_1', worktree => "$wt", branch => 'worktree-agent-1' }, 'agent.started names worktree and branch' );
  like( $finished, { agent_id => 'agent_1', status => 'completed', worktree_kept => F() }, 'agent.finished: not kept' );
  my $entry = $app->tasks->get('agent_1');
  ok( exists $entry->{worktree} && !defined $entry->{worktree} && !defined $entry->{branch}, 'the registry entry names no worktree' );

  my $sub_request = $app->mock_engine->requests->[1];
  like( text_of( $sub_request->{messages}[0] ), qr/^Working directory: \Q$wt\E$/m, 'its mission names the worktree as working directory' );
};

subtest 'changes: the worktree is kept and named in the result, the registry and agent.finished' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my @events;
  my $app = app_in( $repo, { on_event => collect( \@events ) },
    { tool_calls => [ [ agent => { description => 'Write', prompt => 'Write it.', isolation => 'worktree' } ] ] },
    { tool_calls => [ [ write_file => { path => 'new.txt', content => "new\n" } ] ] },
    { text => 'written' },
    { text => 'fine' },
  );
  $app->run('go');
  my $wt = $repo->child('.raider/worktrees/agent-1');
  my ($agent) = @{ results_of( $app, 'agent' ) };
  like( $agent->{text}, qr{\Awritten\nagentId: agent_1 .*</usage>\nworktreePath: \Q$wt\E\nworktreeBranch: worktree-agent-1\z}s,
    'worktreePath and worktreeBranch after the usage' );
  ok( !$agent->{error}, 'not an error' );
  is( $wt->child('new.txt')->slurp, "new\n", 'written in the worktree' );
  ok( !$repo->child('new.txt')->exists, 'not in the main checkout' );
  ok( $git->branch_exists( "$repo", 'worktree-agent-1' ), 'the branch stays' );
  is( git_in( $wt, qw( worktree list --porcelain ) ) =~ /locked/ ? 1 : 0, 0, 'unlocked after the run' );
  like( $app->tasks->get('agent_1'), { worktree => "$wt", branch => 'worktree-agent-1', status => 'completed' },
    'the registry entry carries worktree and branch' );
  my ($finished) = grep { $_->{type} eq 'agent.finished' } @events;
  like( $finished, { worktree_kept => T() }, 'agent.finished: kept' );
};

subtest 'edits into the main checkout are refused before any rule or mode' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in( $repo,
    { tool_calls => [ [ agent => { description => 'Stray', prompt => 'Edit the main one.', isolation => 'worktree' } ] ] },
    { tool_calls => [ [ write_file => { path => "$repo/lib/Main.pm", content => "1;\n" } ] ] },
    { tool_calls => [ [ write_file => { path => '../../../b.txt', content => "b\n" } ] ] },
    { tool_calls => [ [ write_file => { path => "$repo/.raider/worktrees/agent-1/ok.txt", content => "ok\n" } ] ] },
    { text => 'tried' },
    { text => 'fine' },
  );
  $app->run('go');
  my $wt = $repo->child('.raider/worktrees/agent-1');
  my @writes = @{ results_of( $app, 'write_file' ) };
  is( $writes[0], { error => 1, text => "$repo/lib/Main.pm is in the main checkout $repo; this session works in the worktree $wt."
    ." Edit $wt/lib/Main.pm instead." }, 'an absolute path into the main checkout: refused, even in bypassPermissions' );
  is( $writes[1], { error => 1, text => "$repo/b.txt is in the main checkout $repo; this session works in the worktree $wt."
    ." Edit $wt/b.txt instead." }, 'a relative path that leaves the worktree: refused too' );
  is( $writes[2]{error}, 0, 'an absolute path into the worktree is fine' );
  ok( !$repo->child('lib/Main.pm')->exists && !$repo->child('b.txt')->exists, 'nothing written in the main checkout' );
};

subtest 'errors: no git repository, an unsupported isolation value' => sub {
  my $plain = tmpdir();
  my @events;
  my $app = app_in( $plain, { on_event => collect( \@events ) },
    { tool_calls => [ [ agent => { description => 'X', prompt => 'P', isolation => 'worktree' } ] ] },
    { tool_calls => [ [ agent => { description => 'Y', prompt => 'P', isolation => 'sandbox' } ] ] },
    { text => 'fine' },
  );
  $app->run('go');
  my @r = @{ results_of( $app, 'agent' ) };
  is( $r[0], { error => 1, text => 'isolation "worktree" needs a git repository; '.$plain.' is not inside one.' }, 'not a repository' );
  is( $r[1], { error => 1, text => 'Error: isolation "sandbox" is not supported; use "worktree".' }, 'another value' );
  is( scalar @{ $app->mock_engine->requests }, 3, 'no subagent asked the model' );
  ok( !( grep { $_->{type} eq 'agent.started' } @events ), 'nothing started' );
  ok( !$app->tasks->get('agent_1'), 'no agent registered' );
};

subtest 'agent file frontmatter: isolation: worktree always isolates; another value refuses the spawn' => sub {
  my $repo = git_repo(
    '.raider/agents/iso.md' => "---\nname: iso\ndescription: isolated\nisolation: worktree\n---\nWork.\n",
    '.raider/agents/odd.md' => "---\nname: odd\ndescription: odd\nisolation: container\n---\nWork.\n",
  );
  my $app = app_in( $repo,
    { tool_calls => [ [ agent => { description => 'I', prompt => 'P', subagent_type => 'iso' } ] ] },
    { tool_calls => [ [ write_file => { path => 'x.txt', content => "x\n" } ] ] },
    { text => 'did it' },
    { tool_calls => [ [ agent => { description => 'O', prompt => 'P', subagent_type => 'odd', isolation => 'worktree' } ] ] },
    { text => 'fine' },
  );
  $app->run('go');
  my @r = @{ results_of( $app, 'agent' ) };
  like( $r[0]{text}, qr{worktreePath: \Q$repo\E/\.raider/worktrees/agent-1\n}, 'isolated without the call asking for it' );
  ok( $repo->child('.raider/worktrees/agent-1/x.txt')->exists, 'it wrote in its worktree' );
  is( $r[1], { error => 1, text => q{Agent 'odd': isolation "container" is not supported; use "worktree".} },
    'the frontmatter value is refused, whatever the call says' );
  is( $app->context->agent_catalog->find('iso')->{ignored_keys}, [], 'isolation is a used key' );
};

subtest 'a root in a subdirectory works in the same subdirectory of the worktree; the Claude layout uses .claude/worktrees' => sub {
  my $repo = git_repo( 'sub/s.txt' => "s\n", 'CLAUDE.md' => "# project\n", 'sub/CLAUDE.md' => "# sub\n" );
  my $app = app_in( $repo->child('sub'),
    { tool_calls => [ [ agent => { description => 'S', prompt => 'P', isolation => 'worktree' } ] ] },
    { tool_calls => [ [ bash => { command => 'pwd' } ] ] },
    { tool_calls => [ [ glob => { pattern => '*.txt' } ] ] },
    { text => 'ok' },
    { text => 'fine' },
  );
  ok( $app->context->claude_layout, 'the Claude layout' );
  $app->run('go');
  my $wt = $repo->child('.claude/worktrees/agent-1');
  like( results_of( $app, 'bash' )->[0]{text}, qr/\A\Q$wt\E\/sub\n?\z/, 'bash runs in WORKTREE/sub' );
  like( results_of( $app, 'glob' )->[0]{text}, qr/s\.txt/, 'the search tools search there' );
  ok( !$wt->exists, 'removed after (no changes)' );
};

subtest 'background: a kept worktree is named in the notification' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  # The main model answers after 50 ms: the background agent's requests come first.
  my $app = slow_app( root => "$repo", permission_mode => 'bypassPermissions', delay => 0.05, script => [
    { tool_calls => [ [ agent => { description => 'Bg', prompt => 'P', isolation => 'worktree', run_in_background => \1 } ] ] },
    { tool_calls => [ [ write_file => { path => 'bg.txt', content => "bg\n" } ] ] },
    { text => 'bg report' },
    { text => 'main done' },
  ] );
  my $outcome = $app->run_prompt( 'go', wait_background => 1 );
  my $wt = $repo->child('.raider/worktrees/agent-1');
  my ($note) = grep { text_of($_) =~ /<task-notification>/ } @{ $app->mock_engine->requests->[-1]{messages} };
  like( text_of($note), qr{</usage>\n<worktree><worktreePath>\Q$wt\E</worktreePath><worktreeBranch>worktree-agent-1</worktreeBranch></worktree>\n</task-notification>\z},
    'the <worktree> element after the usage' );
  ok( $wt->child('bg.txt')->exists, 'the worktree is kept' );
};

subtest 'send_message resumes in the worktree: reused, checked out again from its branch, made anew' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in( $repo,
    { tool_calls => [ [ agent => { description => 'R', prompt => 'P', isolation => 'worktree' } ] ] },
    { tool_calls => [ [ bash => { command => 'echo one > one.txt && git add one.txt && git commit -q -m one' } ] ] },
    { text => 'committed' },
    { text => 'first' },
  );
  $app->run('go');
  my $wt = $repo->child('.raider/worktrees/agent-1');
  like( results_of( $app, 'agent' )->[0]{text}, qr/worktreeBranch: worktree-agent-1\z/, 'a commit keeps it' );
  git_in( $repo, qw( worktree remove ), "$wt" );
  ok( !$wt->exists && $git->branch_exists( "$repo", 'worktree-agent-1' ), 'worktree gone, branch left' );

  my $sub = $app->tasks->get('agent_1')->{subagent};
  my $resume = sub {
    my ( $message ) = @_;
    my ( $text ) = $sub->resume( $message, { event => sub {}, call => 'c9', task_id => undef, detached => 0 } );
    # Its model answers 'done': the script ran out.
    my $f = $app->tasks->get('agent_1')->{future};
    $app->loop->await($f) if $f;
    return $text;
  };
  is( $resume->('go on'), 'Resuming agent agent_1 in the background. You will be notified when it finishes.', 'resuming' );
  is( $app->tasks->get('agent_1')->{status}, 'completed', 'the resumed run ended' );
  ok( $wt->child('one.txt')->exists, 'the branch is checked out into the same path again' );
  is( $sub->last_outcome->{worktree}, { path => "$wt", branch => 'worktree-agent-1' }, 'kept: its commit is beyond the base' );

  # Both gone: made anew from the base.
  $git->remove( dir => "$repo", path => "$wt", branch => 'worktree-agent-1', force => 1 );
  $resume->('and again');
  is( $sub->last_outcome->{status}, 'completed', 'the run completed' );
  ok( !$sub->last_outcome->{worktree}, 'made anew, unchanged, removed again' );
  ok( !$wt->exists && !$git->branch_exists( "$repo", 'worktree-agent-1' ), 'worktree and branch gone' );
};

subtest 'an agent ID whose worktree is left from earlier is skipped' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  $git->create( source => "$repo", path => $repo->child('.raider/worktrees/agent-1'), branch => 'worktree-agent-1', base => 'HEAD' );
  my $app = app_in( $repo,
    { tool_calls => [ [ agent => { description => 'N', prompt => 'P', isolation => 'worktree' } ] ] },
    { text => 'r' },
    { text => 'fine' },
  );
  $app->run('go');
  like( results_of( $app, 'agent' )->[0]{text}, qr/agentId: agent_2 /, 'agent_2: the old agent-1 worktree is not reused' );
  ok( $repo->child('.raider/worktrees/agent-1')->exists, 'the old one is left alone' );
};

subtest 'a git command that fails keeps the worktree, the answer goes on' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in( $repo,
    { tool_calls => [ [ agent => { description => 'F', prompt => 'P', isolation => 'worktree' } ] ] },
    { text => 'r' },
    { text => 'fine' },
  );
  no warnings 'redefine';
  local *Langertha::Raider::Worktree::remove = sub { { error => 'git worktree remove: fatal: simulated' } };
  is( '' . $app->run('go'), 'fine', 'the run answers' );
  my $wt = $repo->child('.raider/worktrees/agent-1');
  like( results_of( $app, 'agent' )->[0]{text},
    qr{</usage>\nworktreePath: \Q$wt\E\nworktreeBranch: worktree-agent-1\nworktree kept: git worktree remove: fatal: simulated\z},
    'worktree kept: REASON' );
  ok( $wt->exists, 'kept' );
};

subtest 'a cancelled run nobody hears of names its kept worktree in a meta line' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  # The agent's model takes 30 s: it is still running when the conversation is cleared.
  my $app = slow_app( root => "$repo", permission_mode => 'bypassPermissions', sub_delay => 30, script => [
    { tool_calls => [ [ agent => { description => 'C', prompt => 'P', isolation => 'worktree', run_in_background => \1 } ] ] },
    { text => 'main done' },
  ] );
  $app->run('go');
  my $wt = $repo->child('.raider/worktrees/agent-1');
  ok( $wt->exists, 'the background agent works in its worktree' );
  $wt->child('wip.txt')->spew("wip\n");    # its work so far
  $app->note_history_cleared;              # /clear: stopped without a notification
  is( $app->tasks->get('agent_1')->{status}, 'killed', 'stopped' );
  is( [ $app->take_meta_notes ], [ 'agent agent_1 left its worktree '.$wt.' on branch worktree-agent-1' ], 'the meta line' );
  is( $app->notifications_pending, 0, 'no notification' );
  ok( $wt->child('wip.txt')->exists, 'kept' );
  ok( !( git_in( $wt, qw( worktree list --porcelain ) ) =~ /locked/ ), 'and unlocked' );
};

subtest 'leaving raider: the kept worktree of a stopped background agent is a meta line too' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = slow_app( root => "$repo", permission_mode => 'bypassPermissions', sub_delay => 30, script => [
    { tool_calls => [ [ agent => { description => 'L', prompt => 'P', isolation => 'worktree', run_in_background => \1 } ] ] },
    { text => 'main done' },
  ] );
  $app->run('go');
  my $wt = $repo->child('.raider/worktrees/agent-1');
  $wt->child('wip.txt')->spew("wip\n");
  is( $app->stop_background, 1, 'leaving stops it' );
  is( [ $app->take_meta_notes ], [ 'agent agent_1 left its worktree '.$wt.' on branch worktree-agent-1' ], 'the meta line' );
};

subtest 'nested: a subagent of an isolated one works in the same worktree; an isolated one gets its own' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in( $repo,
    { tool_calls => [ [ agent => { description => 'Outer', prompt => 'P', isolation => 'worktree' } ] ] },
    { tool_calls => [ [ agent => { description => 'Inner', prompt => 'Q' } ] ] },
    { tool_calls => [ [ bash => { command => 'pwd' } ], [ write_file => { path => "$repo/inner.txt", content => "i\n" } ] ] },
    { text => 'inner done' },
    { tool_calls => [ [ agent => { description => 'Own', prompt => 'R', isolation => 'worktree' } ] ] },
    { tool_calls => [ [ bash => { command => 'pwd' } ] ] },
    { text => 'own done' },
    { text => 'outer done' },
    { text => 'fine' },
  );
  $app->run('go');
  my $outer = $repo->child('.raider/worktrees/agent-1');
  my @bash = @{ results_of( $app, 'bash' ) };
  like( $bash[0]{text}, qr/\A\Q$outer\E\n?\z/, 'the inner agent\'s bash runs in the outer agent\'s worktree' );
  like( results_of( $app, 'write_file' )->[0]{text}, qr/\A\Q$repo\E\/inner\.txt is in the main checkout /,
    'and it cannot edit the main checkout either' );
  like( $bash[1]{text}, qr/\A\Q$repo\E\/\.raider\/worktrees\/agent-3\n?\z/,
    'an isolated agent of an isolated one: its own worktree under the main checkout, not nested' );
};

subtest 'an isolated agent of an earlier process resumes in its kept worktree' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $first = app_in( $repo,
    { tool_calls => [ [ agent => { description => 'Keep', prompt => 'P', isolation => 'worktree', name => 'keeper' } ] ] },
    { tool_calls => [ [ write_file => { path => 'kept.txt', content => "k\n" } ] ] },
    { text => 'kept it' },
    { text => 'bye' },
  );
  my $session = $first->create_session;
  $first->run_prompt( 'go', session => $session );
  my $id = $session->id;
  $session->release;
  undef $first;
  my $wt = $repo->child('.raider/worktrees/agent-1');
  ok( $wt->child('kept.txt')->exists, 'kept by the first process' );

  my $app = app_in( $repo,
    { tool_calls => [ [ send_message => { to => 'keeper', message => 'look again' } ] ] },
    { text => 'main first' },
    { tool_calls => [ [ bash => { command => 'pwd; ls' } ] ] },
    { text => 'still there' },
    { text => 'main final' },
  );
  my $again = $app->open_session($id);
  $app->replay_session($again);
  is( $app->run_prompt( 'continue', session => $again, wait_background => 1 )->{response}, 'main final', 'the run answers' );
  like( results_of( $app, 'bash' )->[0]{text}, qr/\A\Q$wt\E\n.*kept\.txt/s, 'the restored agent works in its worktree again' );
  like( $app->tasks->get('agent_1'), { worktree => "$wt", branch => 'worktree-agent-1' }, 'kept again (it has the file)' );
};

subtest 'worktree_base_ref: Claude settings in the Claude layout, the config otherwise' => sub {
  my $native = git_repo( '.raider/config.yml' => "worktree_base_ref: head\n" );
  is( mock_app( root => "$native" )->worktree_base_ref, 'head', 'worktree_base_ref of .raider/config.yml' );
  my $claude = git_repo( '.claude/settings.json' => '{"worktree":{"baseRef":"head"}}' );
  my $app = mock_app( root => "$claude" );
  ok( $app->context->claude_layout, 'Claude layout' );
  is( $app->worktree_base_ref, 'head', 'worktree.baseRef of the Claude settings' );
  is( mock_app( root => ''.git_repo() )->worktree_base_ref, 'fresh', 'default fresh' );
  is( mock_app( root => ''.git_repo( '.raider/config.yml' => "worktree_base_ref: sideways\n" ) )->worktree_base_ref, 'fresh',
    'another value counts as fresh' );
};

done_testing;
