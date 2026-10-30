#!/usr/bin/env perl
# ABSTRACT: enter_worktree and exit_worktree: texts, validation, path form, removal, permissions, hooks (ADR 0032 §4, §6; k168)
use strict;
use warnings;
use utf8;
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
use Test::Raider::Git qw( have_git git_repo git_in );
use Test::Raider::MockAI qw( mock_app );
use Langertha::Raider::Worktree;
use Langertha::Raider::WorktreeTools;

plan skip_all => 'needs git' unless have_git();

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $git = Langertha::Raider::Worktree->new;
my @dirs;
sub tmpdir { my $d = Path::Tiny->tempdir; push @dirs, $d; $d->realpath }

sub collect { my ( $list ) = @_; return sub { my ( $type, %p ) = @_; push @$list, { type => $type, %p } } }

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

# A call of a tool straight through the application's handler, as the
# server runs it: ( text, is_error ).
sub tool {
  my ( $app, $name, $in ) = @_;
  my ($tool) = grep { $_->name eq $name } map { @{ $_->tools } } @{ $app->_tool_servers };
  my $r = $tool->call( $in // {}, {} );
  return ( $r->{content}[0]{text}, $r->{isError} ? 1 : 0 );
}

# The gate's verdict on a call, with the source of the worktree tools' server.
sub gate {
  my ( $app, $name, $args ) = @_;
  return $app->tool_gate->( undef, { name => $name, source => 'engine:9', arguments => $args // {} } );
}

subtest 'enter by name, exit with remove: texts, branch, journal' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my @events;
  my $app = app_in( $repo, { on_event => collect( \@events ) },
    { tool_calls => [ [ enter_worktree => { name => 'feature/x' } ] ] },
    { tool_calls => [ [ exit_worktree => { action => 'remove' } ] ] },
    { text => 'done' },
  );
  my $session = $app->create_session;
  $app->run_prompt( 'go', session => $session );
  my $wt = $repo->child('.raider/worktrees/feature/x');
  my ($enter) = @{ results_of( $app, 'enter_worktree' ) };
  is( $enter, { error => 0, text => "Entered worktree at \x{201C}$wt\x{201D} on branch \x{201C}worktree-feature/x\x{201D}."
    .' The session is now working in the worktree. Use exit_worktree to leave mid-session; when the session ends it is'
    .' removed if unchanged and kept otherwise.' }, 'the entered text of ADR 0032' );
  my ($exit) = @{ results_of( $app, 'exit_worktree' ) };
  is( $exit, { error => 0, text => "Removed the worktree $wt and its branch worktree-feature/x. Working directory: $repo." },
    'removed: worktree and branch' );
  ok( !$wt->exists, 'the directory is gone' );
  ok( !$git->branch_exists( "$repo", 'worktree-feature/x' ), 'the branch too' );
  is( $app->working_root, "$repo", 'back at the root' );
  my @wt_events = grep { $_->{type} =~ /\Aworktree\./ } @events;
  is( \@wt_events, [
    { type => 'worktree.entered', path => "$wt", branch => 'worktree-feature/x', created => T() },
    { type => 'worktree.exited', path => "$wt", branch => 'worktree-feature/x', removed => T(), reason => 'exit_worktree' },
  ], 'worktree.entered and worktree.exited' );
  $session->release;
  my @journal = map { $json->decode($_) } $session->path->lines_raw;
  is( [ map { [ $_->{type}, $_->{run} ] } grep { $_->{type} =~ /\Aworktree\./ } @journal ],
    [ [ 'worktree.entered', 'r1' ], [ 'worktree.exited', 'r1' ] ], 'both in the session journal, in the run' );
};

subtest 'names: session-N by default, skipping what exists; the rule; an existing name is an error' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  git_in( $repo, qw( branch worktree-session-1 ) );
  $repo->child('.raider/worktrees/session-2')->mkpath;
  my $app = app_in($repo);
  my ( $text, $err ) = tool( $app, 'enter_worktree' );
  ok( !$err, 'entered' ) or diag $text;
  is( $app->worktree_session->{path}, $repo->child('.raider/worktrees/session-3')->stringify,
    'session-1 has a branch, session-2 a directory: session-3' );
  ( $text, $err ) = tool( $app, 'enter_worktree', { name => 'other' } );
  is( [ $text, $err ], [ 'Already working in the worktree '.$repo->child('.raider/worktrees/session-3')
    .'; pass path to switch to another one, or exit_worktree first.', 1 ], 'no second one by name' );
  ( $text, $err ) = tool( $app, 'exit_worktree', { action => 'remove' } );
  ok( !$err, 'removed' ) or diag $text;

  for my $bad ( 'a b', 'x' x 65, 'a//b', '/abs', 'a/../b', '..', 'ä' ) {
    ( $text, $err ) = tool( $app, 'enter_worktree', { name => $bad } );
    ok( $err && $text =~ /\AInvalid worktree name/, 'refused: '.$bad ) or diag $text;
  }
  ( $text, $err ) = tool( $app, 'enter_worktree', { name => 'ok/fine-1.2_x' } );
  ok( !$err, 'segments of letters, digits, dot, dash, underscore joined by /' ) or diag $text;
  tool( $app, 'exit_worktree', { action => 'remove' } );

  git_in( $repo, qw( branch worktree-taken ) );
  ( $text, $err ) = tool( $app, 'enter_worktree', { name => 'taken' } );
  is( [ $text, $err ], [ 'Worktree taken exists; pass path to enter it.', 1 ], 'an existing branch: an error, no reuse' );
  $repo->child('.raider/worktrees/there')->mkpath;
  ( $text, $err ) = tool( $app, 'enter_worktree', { name => 'there' } );
  is( [ $text, $err ], [ 'Worktree there exists; pass path to enter it.', 1 ], 'an existing directory too' );

  ( $text, $err ) = tool( $app, 'enter_worktree', { name => 'a', path => 'b' } );
  is( [ $text, $err ], [ 'Pass name or path, not both.', 1 ], 'name and path together' );
  is( $app->working_root, "$repo", 'nothing moved' );
};

subtest 'no git repository; the Claude layout uses .claude/worktrees' => sub {
  my $plain = tmpdir();
  my $app = app_in($plain);
  my ( $text, $err ) = tool( $app, 'enter_worktree' );
  is( [ $text, $err ], [ "enter_worktree needs a git repository; $plain is not inside one.", 1 ], 'not a repository' );
  ( $text, $err ) = tool( $app, 'exit_worktree', { action => 'keep' } );
  is( [ $text, $err ], [ 'No worktree session is active; nothing changed.', 0 ], 'exit outside a session: no error' );
  ( $text, $err ) = tool( $app, 'exit_worktree', { action => 'drop' } );
  is( [ $text, $err ], [ 'action must be "keep" or "remove".', 1 ], 'an unknown action' );

  my $claude = git_repo( '.claude/settings.json' => '{}' );
  $app = app_in($claude);
  ok( $app->context->claude_layout, 'Claude layout' );
  ( $text, $err ) = tool( $app, 'enter_worktree' );
  ok( !$err, 'entered' ) or diag $text;
  is( $app->working_root, $claude->child('.claude/worktrees/session-1')->stringify, 'below .claude/worktrees' );
  my ($tool) = grep { $_->name eq 'enter_worktree' } map { @{ $_->tools } } @{ $app->_tool_servers };
  like( $tool->description, qr{inside \.claude/worktrees/ of the repository.*worktree\.baseRef}s, 'its text names the layout' );
  tool( $app, 'exit_worktree', { action => 'remove' } );
};

subtest 'remove with changes is refused and lists them; discard_changes removes anyway' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in($repo);
  tool( $app, 'enter_worktree', { name => 'work' } );
  my $wt = $repo->child('.raider/worktrees/work');
  $wt->child('a.txt')->spew("changed\n");
  $wt->child('b.txt')->spew("b\n");
  git_in( $wt, qw( add b.txt ) );
  git_in( $wt, qw( commit -q -m b ) );
  $wt->child('c.txt')->spew("c\n");
  my ( $text, $err ) = tool( $app, 'exit_worktree', { action => 'remove' } );
  is( [ $text, $err ], [ join( "\n", "The worktree $wt has changes; nothing was removed.", 'git status --porcelain:',
    ' M a.txt', '?? c.txt', '1 commit beyond its base.', 'Pass discard_changes: true to remove it anyway.' ), 1 ],
    'the porcelain lines and the commits beyond the base' );
  ok( $wt->exists, 'still there' );
  is( $app->working_root, "$wt", 'still working in it' );
  ( $text, $err ) = tool( $app, 'exit_worktree', { action => 'remove', discard_changes => JSON::MaybeXS->true } );
  is( [ $text, $err ], [ "Removed the worktree $wt and its branch worktree-work. Working directory: $repo.", 0 ],
    'removed with --force, the branch with its commit deleted' );
  ok( !$wt->exists && !$git->branch_exists( "$repo", 'worktree-work' ), 'gone' );
};

subtest 'keep; a removal git refuses keeps the worktree and moves back' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in($repo);
  tool( $app, 'enter_worktree', { name => 'kept' } );
  my $wt = $repo->child('.raider/worktrees/kept');
  my ( $text, $err ) = tool( $app, 'exit_worktree', { action => 'keep' } );
  is( [ $text, $err ], [ "Left the worktree $wt; it stays on branch worktree-kept. Working directory: $repo.", 0 ], 'keep' );
  ok( $wt->exists && $git->branch_exists( "$repo", 'worktree-kept' ), 'worktree and branch stay' );
  is( $app->worktree_session, undef, 'no longer tracked' );

  tool( $app, 'enter_worktree', { name => 'locked' } );
  $wt = $repo->child('.raider/worktrees/locked');
  git_in( $repo, qw( worktree lock ), "$wt" );
  ( $text, $err ) = tool( $app, 'exit_worktree', { action => 'remove' } );
  like( $text, qr/\Aworktree kept: git worktree remove: fatal: .*locked.*\. Working directory: \Q$repo\E\.\z/s,
    'worktree kept: REASON' );
  is( $err, 1, 'an error result' );
  is( $app->working_root, "$repo", 'the working root is back at the root' );
  ok( $wt->exists, 'the worktree stays' );
  git_in( $repo, qw( worktree unlock ), "$wt" );
};

subtest 'path: a listed worktree, entered, only ever kept; the previous one is left untouched' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $other = $repo->child('.raider/worktrees/manual');
  git_in( $repo, qw( worktree add -q -b manual ), "$other" );
  my @events;
  my $app = app_in( $repo, { on_event => collect( \@events ) } );
  tool( $app, 'enter_worktree', { name => 'mine' } );
  my $mine = $repo->child('.raider/worktrees/mine');
  my ( $text, $err ) = tool( $app, 'enter_worktree', { path => '.raider/worktrees/manual' } );
  is( [ $text, $err ], [ "Entered worktree at \x{201C}$other\x{201D} on branch \x{201C}manual\x{201D}. The session is now"
    .' working in the worktree. Use exit_worktree to leave mid-session; it was entered by path, so it stays on disk when the'
    .' session ends.', 0 ], 'a root-relative path enters it' );
  is( $app->working_root, "$other", 'working there' );
  ok( $mine->exists, 'the previous one stays on disk' );
  ok( !$app->worktree_session->{created}, 'tracked as entered' );
  ( $text, $err ) = tool( $app, 'exit_worktree', { action => 'remove' } );
  is( [ $text, $err ], [ "$other was entered by path, not created by this session; use action \"keep\".", 1 ], 'no removal' );
  $app->close_worktree_session('session_end');
  ok( $other->exists && $mine->exists, 'the session end only leaves it; the earlier one is not tracked any more' );
  is( [ map { [ $_->{type}, $_->{created} // $_->{reason} ] } grep { $_->{type} =~ /\Aworktree\./ } @events ],
    [ [ 'worktree.entered', T() ], [ 'worktree.entered', F() ], [ 'worktree.exited', 'session_end' ] ], 'the journal events' );

  ( $text, $err ) = tool( $app, 'enter_worktree', { path => "$repo" } );
  is( [ $text, $err ], [ "$repo is the main checkout; pass the path of a linked worktree.", 1 ], 'not the main checkout' );
  my $nowhere = tmpdir();
  ( $text, $err ) = tool( $app, 'enter_worktree', { path => "$nowhere" } );
  is( [ $text, $err ], [ "$nowhere is not a worktree of the repository at $repo (git worktree list).", 1 ], 'not listed' );
};

subtest 'path outside the worktree directories: always asked, only bypassPermissions skips' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $outside = tmpdir()->child('elsewhere');
  git_in( $repo, qw( worktree add -q -b elsewhere ), "$outside" );
  my $inside = $repo->child('.claude/worktrees/in');
  git_in( $repo, qw( worktree add -q -b in ), "$inside" );
  my $rules = $repo->child('.raider/config.yml');
  $rules->touchpath->spew("permissions:\n  allow:\n    - EnterWorktree\n");

  my @asked;
  my $app = mock_app( root => "$repo", permission_mode => 'acceptEdits',
    on_permission_request => sub { push @asked, $_[0]; { answer => 'session' } } );
  my $v = gate( $app, enter_worktree => { path => "$outside" } );
  is( $v->{verdict}, 'allow', 'the person said yes' );
  is( scalar @asked, 1, 'asked although a rule and the mode allow it' );
  like( $asked[0], { tool => 'enter_worktree', rule => undef,
    reason => "enter_worktree would move the session into $outside, which is outside $repo/.claude/worktrees/ and"
      ." $repo/.raider/worktrees/; the user is asked every time" }, 'with the reason, no rule to offer' );
  is( [ map { $_->text } @{ $app->permissions->session_rules } ], [], '"for this session" adds no rule' );
  gate( $app, enter_worktree => { path => "$outside" } );
  is( scalar @asked, 2, 'asked again the next time' );
  is( gate( $app, enter_worktree => { path => "$inside" } )->{verdict}, 'allow', 'inside .claude/worktrees: the rule holds' );
  is( scalar @asked, 2, 'not asked' );

  my $nobody = mock_app( root => "$repo", permission_mode => 'acceptEdits' );
  $v = gate( $nobody, enter_worktree => { path => "$outside" } );
  is( $v->{verdict}, 'deny', 'nobody to ask: refused' );
  like( $v->{message}, qr/\APermission to use enter_worktree has been denied\. Reason: enter_worktree would move the session into \Q$outside\E,.*; nobody can approve it in this run\. Only --permission-mode bypassPermissions skips this question\. Do not retry/s,
    'and says only bypassPermissions skips it' );

  my $bypass = mock_app( root => "$repo", permission_mode => 'bypassPermissions',
    on_permission_request => sub { die "not asked\n" } );
  is( gate( $bypass, enter_worktree => { path => "$outside" } )->{verdict}, 'allow', 'bypassPermissions: no question' );
  $rules->spew("permissions:\n  deny:\n    - EnterWorktree\n");
  my $denied = mock_app( root => "$repo", permission_mode => 'default',
    on_permission_request => sub { die "not asked\n" } );
  is( gate( $denied, enter_worktree => { path => "$outside" } )->{verdict}, 'deny', 'a deny rule still refuses first' );
};

subtest 'permission modes and rules in Claude Code\'s names' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my %v = map { $_ => gate( mock_app( root => "$repo", permission_mode => $_ ), enter_worktree => { name => 'x' } ) }
    qw( default acceptEdits auto plan );
  is( $v{default}{verdict}, 'deny', 'default: asked (nobody here: refused)' );
  like( $v{default}{reason}, qr/default mode asks before this call: enter_worktree changes files/, 'a write tool' );
  is( $v{acceptEdits}{verdict}, 'allow', 'acceptEdits: allowed' );
  is( $v{auto}{verdict}, 'allow', 'auto: allowed' );
  is( [ @{ $v{plan} }{qw( verdict by )} ], [ 'deny', 'mode' ], 'plan: refused' );
  like( $v{plan}{reason}, qr/plan mode: enter_worktree changes files/, 'plan mode says why' );
  is( gate( mock_app( root => "$repo", permission_mode => 'default' ), exit_worktree => { action => 'keep' } )->{verdict},
    'deny', 'exit_worktree too' );

  $repo->child('.raider/config.yml')->touchpath->spew("permissions:\n  allow:\n    - EnterWorktree\n  deny:\n    - ExitWorktree\n");
  my $app = mock_app( root => "$repo", permission_mode => 'default' );
  is( gate( $app, enter_worktree => { name => 'x' } )->{verdict}, 'allow', 'EnterWorktree allow rule' );
  is( gate( $app, exit_worktree => { action => 'keep' } )->{verdict}, 'deny', 'ExitWorktree deny rule' );
};

subtest 'hook matchers name them EnterWorktree and ExitWorktree' => sub {
  my $out = tmpdir();
  my $repo = git_repo(
    '.claude/settings.json' => $json->encode({ hooks => { PreToolUse => [
      { matcher => 'EnterWorktree|ExitWorktree', hooks => [ { type => 'command',
        command => 'cat >> '.$out.'/in.jsonl; echo >> '.$out.'/in.jsonl' } ] } ] } }),
  );
  my $app = app_in( $repo, { claude => 1 },
    { tool_calls => [ [ enter_worktree => { name => 'h' } ] ] },
    { tool_calls => [ [ exit_worktree => { action => 'remove' } ] ] },
    { text => 'ok' },
  );
  $app->run('go');
  my @in = map { $json->decode($_) } grep { /\S/ } $out->child('in.jsonl')->lines_raw;
  is( [ map { [ $_->{tool_name}, $_->{tool_input} ] } @in ],
    [ [ 'EnterWorktree', { name => 'h' } ], [ 'ExitWorktree', { action => 'remove' } ] ], 'both hooks ran with Claude names' );
  is( [ map { $_->{cwd} } @in ], [ "$repo", $repo->child('.claude/worktrees/h')->stringify ], 'cwd: before and inside' );
};

subtest 'the tool texts' => sub {
  my $tools = Langertha::Raider::WorktreeTools->new( enter_handler => sub { }, exit_handler => sub { } );
  like( $tools->enter_description, qr/\AUse this tool ONLY when explicitly instructed to work in a worktree/, 'enter: Claude Code\'s opening' );
  like( $tools->enter_description, qr{inside \.raider/worktrees/ of the repository on a new branch worktree-NAME}, 'raider layout by default' );
  like( $tools->enter_description, qr/the name is session-N/, 'the default name' );
  like( $tools->exit_description, qr/\AExit a worktree session started by enter_worktree/, 'exit: Claude Code\'s opening' );
  unlike( $tools->enter_description . $tools->exit_description, qr/EnterWorktree|ExitWorktree|WorktreeCreate/, 'raider\'s names only' );
  my $dies = Langertha::Raider::WorktreeTools->new( enter_handler => sub { die "boom\n" }, exit_handler => sub { } );
  my ($enter) = grep { $_->name eq 'enter_worktree' } @{ $dies->server->tools };
  is( $enter->call( {}, {} ), { content => [ { type => 'text', text => 'boom' } ], isError => T() }, 'a handler that dies: an error result' );
};

done_testing;
