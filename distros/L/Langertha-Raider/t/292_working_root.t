#!/usr/bin/env perl
# ABSTRACT: The working root follows enter_worktree: tools, policy, hooks, mission, subagents (ADR 0032 §3; k168)
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
use Scalar::Util qw( refaddr );
use Test::Raider::Git qw( have_git git_repo git_in );
use Test::Raider::MockAI qw( mock_app );

plan skip_all => 'needs git' unless have_git();

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
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

subtest 'the file, search and shell tools work in the worktree from the next call on' => sub {
  my $repo = git_repo( 'a.txt' => "main a\n", 'lib/A.pm' => "package A; # MARK\n1;\n" );
  my $app = app_in( $repo,
    { tool_calls => [ [ enter_worktree => {} ] ] },
    { tool_calls => [ [ write_file => { path => 'new.txt', content => "new\n" } ] ] },
    { tool_calls => [ [ bash => { command => 'pwd' } ] ] },
    { tool_calls => [ [ grep => { pattern => 'MARK', output_mode => 'files_with_matches' } ] ] },
    { tool_calls => [ [ glob => { pattern => '*.txt' } ] ] },
    { tool_calls => [ [ read_file => { path => 'a.txt' } ] ] },
    { tool_calls => [ [ list_files => { path => '.' } ] ] },
    { text => 'worked' },
  );
  is( '' . $app->run('go'), 'worked', 'the run answers' );
  my $wt = $repo->child('.raider/worktrees/session-1');
  is( $app->working_root, "$wt", 'the working root is the worktree' );
  is( $app->root, "$repo", 'the root stays' );
  is( $wt->child('new.txt')->slurp, "new\n", 'write_file: a relative path lands in the worktree' );
  ok( !$repo->child('new.txt')->exists, 'not in the main checkout' );
  like( results_of( $app, 'bash' )->[0]{text}, qr/\A\Q$wt\E$/m, 'bash starts in the worktree' );
  like( results_of( $app, 'grep' )->[0]{text}, qr/^lib\/A\.pm$/m, 'grep searches the worktree, paths relative to it' );
  like( results_of( $app, 'glob' )->[0]{text}, qr/new\.txt/, 'glob sees the file only the worktree has' );
  like( results_of( $app, 'read_file' )->[0]{text}, qr/main a/, 'read_file reads the copy' );
  like( results_of( $app, 'list_files' )->[0]{text}, qr/new\.txt/, 'list_files lists the worktree' );
  is( $app->permissions->root, "$wt", 'the policy\'s root is the worktree' );
  is( $app->permissions->worktree_isolation, { top => "$repo", worktree => "$wt" }, 'and it knows the main checkout' );
};

subtest 'edits into the main checkout are refused while the working root is a worktree' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in( $repo,
    { tool_calls => [ [ enter_worktree => { name => 'iso' } ] ] },
    { tool_calls => [ [ write_file => { path => "$repo/b.txt", content => "b\n" } ] ] },
    { tool_calls => [ [ edit_file => { path => '../../../a.txt', old_string => 'a', new_string => 'x' } ] ] },
    { tool_calls => [ [ exit_worktree => { action => 'keep' } ] ] },
    { tool_calls => [ [ write_file => { path => 'c.txt', content => "c\n" } ] ] },
    { text => 'tried' },
  );
  $app->run('go');
  my $wt = $repo->child('.raider/worktrees/iso');
  my @writes = @{ results_of( $app, 'write_file' ) };
  is( $writes[0], { error => 1, text => "$repo/b.txt is in the main checkout $repo; this session works in the worktree $wt."
    ." Edit $wt/b.txt instead." }, 'an absolute path: refused, even in bypassPermissions' );
  is( results_of( $app, 'edit_file' )->[0], { error => 1, text => "$repo/a.txt is in the main checkout $repo; this session"
    ." works in the worktree $wt. Edit $wt/a.txt instead." }, 'a relative path that leaves the worktree too' );
  ok( !$repo->child('b.txt')->exists && $repo->child('a.txt')->slurp eq "a\n", 'the main checkout is untouched' );
  ok( !$writes[1]{error} && $repo->child('c.txt')->slurp eq "c\n", 'back at the root: writing there works again' );
  ok( !$app->permissions->has_worktree_isolation, 'the policy is back without isolation' );
  is( $app->permissions->root, "$repo", 'and at the root' );
};

subtest 'the next mission names the worktree; the current raid goes on' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in( $repo,
    { tool_calls => [ [ enter_worktree => {} ] ] },
    { text => 'in' },
    { tool_calls => [ [ exit_worktree => { action => 'keep' } ] ] },
    { text => 'out' },
    { text => 'back' },
  );
  my $wt = $repo->child('.raider/worktrees/session-1');
  is( $app->run_prompt('one')->{response}, 'in', 'first run' );
  my @req = @{ $app->mock_engine->requests };
  like( text_of( $req[1]{messages}[0] ), qr/^Working directory: \Q$repo\E$/m, 'the raid that entered keeps its mission' );
  is( $app->run_prompt('two')->{response}, 'out', 'second run' );
  @req = @{ $app->mock_engine->requests };
  like( text_of( $req[2]{messages}[0] ), qr/^Working directory: \Q$wt\E$/m, 'the next run names the worktree' );
  $app->run_prompt('three');
  @req = @{ $app->mock_engine->requests };
  like( text_of( $req[4]{messages}[0] ), qr/^Working directory: \Q$repo\E$/m, 'after exit_worktree the root again' );
};

subtest 'a root in a subdirectory works in the same subdirectory of the worktree' => sub {
  my $repo = git_repo( 'sub/x.txt' => "x\n" );
  my $app = app_in( $repo->child('sub'),
    { tool_calls => [ [ enter_worktree => { name => 'deep' } ] ] },
    { tool_calls => [ [ bash => { command => 'pwd' } ] ] },
    { text => 'ok' },
  );
  $app->run('go');
  my $wt = $repo->child('.raider/worktrees/deep');
  is( $app->working_root, $wt->child('sub')->stringify, 'the working root is the subdirectory of the worktree' );
  like( results_of( $app, 'bash' )->[0]{text}, qr/\A\Q$wt\E\/sub$/m, 'bash starts there' );
};

subtest '/reload keeps the working root and the tools following it' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in( $repo,
    { tool_calls => [ [ enter_worktree => {} ] ] },
    { text => 'in' },
    { tool_calls => [ [ write_file => { path => "$repo/x.txt", content => "x\n" } ] ] },
    { tool_calls => [ [ bash => { command => 'pwd' } ] ] },
    { text => 'done' },
  );
  $app->run_prompt('one');
  my $servers = [ @{ $app->_tool_servers } ];
  $app->reload_context;
  $app->reload_mission;
  my $wt = $repo->child('.raider/worktrees/session-1');
  is( $app->permissions->root, "$wt", 'the policy read again is rooted in the worktree' );
  ok( $app->permissions->has_worktree_isolation, 'with the isolation' );
  $app->run_prompt('two');
  like( results_of( $app, 'write_file' )->[0]{text}, qr/is in the main checkout/, 'edits into the main checkout still refused' );
  like( results_of( $app, 'bash' )->[0]{text}, qr/\A\Q$wt\E$/m, 'bash still in the worktree' );
  is( [ map { refaddr $_ } @{ $app->_tool_servers }[ 0 .. 5 ] ], [ map { refaddr $_ } @$servers[ 0 .. 5 ] ],
    'the stock servers stay mounted as they were' );
};

subtest 'subagents spawned in the worktree inherit it; an isolated one branches from it' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in( $repo, { max_agent_depth => 2 },
    { tool_calls => [ [ enter_worktree => {} ] ] },
    { tool_calls => [ [ bash => { command => 'echo wt > wt.txt && git add wt.txt && git commit -q -m wt && pwd' } ] ] },
    { tool_calls => [ [ agent => { description => 'Plain', prompt => 'Look.' } ] ] },
    { tool_calls => [ [ bash => { command => 'pwd' } ] ] },
    { tool_calls => [ [ grep => { pattern => 'wt', output_mode => 'files_with_matches' } ] ] },
    { text => 'plain done' },
    { tool_calls => [ [ agent => { description => 'Iso', prompt => 'Look isolated.', isolation => 'worktree' } ] ] },
    { tool_calls => [ [ bash => { command => 'pwd; ls' } ] ] },
    { text => 'iso done' },
    { text => 'all done' },
  );
  is( '' . $app->run('go'), 'all done', 'the run answers' );
  my $wt = $repo->child('.raider/worktrees/session-1');
  my @bash = @{ results_of( $app, 'bash' ) };
  like( $bash[1]{text}, qr/\A\Q$wt\E$/m, 'a plain subagent\'s bash starts in the working root' );
  like( results_of( $app, 'grep' )->[0]{text}, qr/^wt\.txt$/m, 'its search tools too' );
  my $iso = $repo->child('.raider/worktrees/agent-2');
  like( $bash[2]{text}, qr/\A\Q$iso\E\n/, 'an isolated one works in its own worktree, under the main top' );
  like( $bash[2]{text}, qr/^wt\.txt$/m, 'branched from the worktree\'s HEAD (fresh falls back to the working root\'s HEAD)' );
  my @req = @{ $app->mock_engine->requests };
  like( text_of( $req[3]{messages}[0] ), qr/^Working directory: \Q$wt\E$/m, 'the plain subagent\'s mission names the working root' );
};

subtest 'a subagent started at the root stays there when the main run moves' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in( $repo );
  my $sub = Langertha::Raider::Subagent->new(
    app             => $app,
    agent           => $app->context->agent_catalog->find('general-purpose'),
    depth           => 1,
    prompt          => 'x',
    caller_servers  => $app->_tool_servers,
    on_caller_event => sub { },
  );
  my %tool = map { $_->name => $_ } map { @{ $_->tools } } @{ $sub->tool_servers };
  my ( $wt_path ) = do {
    my ( $text, $err ) = $app->_enter_worktree({ name => 'later' });
    ok( !$err, 'entered' ) or diag $text;
    $app->working_root;
  };
  $wt_path = path($wt_path);
  $wt_path->child('only-in-wt.txt')->spew("w\n");
  my $r = $tool{glob}->call( { pattern => '*.txt' }, {} );
  my $text = $r->{content}[0]{text};
  like( $text, qr/a\.txt/, 'its glob still searches the root' );
  unlike( $text, qr/only-in-wt/, 'not the worktree' );
  is( $sub->working_root, "$repo", 'its working root is the root' );
  $app->close_worktree_session('clear');
};

subtest 'perl_eval runs in the working root; an isolated subagent\'s in its own worktree' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $code = 'use Cwd; print Cwd::getcwd()';
  my $app = app_in( $repo, { perl => 1 },
    { tool_calls => [ [ perl_eval => { code => $code } ] ] },
    { tool_calls => [ [ enter_worktree => {} ] ] },
    { tool_calls => [ [ perl_eval => { code => $code } ] ] },
    { tool_calls => [ [ agent => { description => 'Iso', prompt => 'Where?', isolation => 'worktree' } ] ] },
    { tool_calls => [ [ perl_eval => { code => $code } ] ] },
    { text => 'here' },
    { text => 'done' },
  );
  $app->run('go');
  my @evals = map { $json->decode( $_->{text} )->{stdout} } @{ results_of( $app, 'perl_eval' ) };
  my $wt = $repo->child('.raider/worktrees/session-1');
  is( $evals[0], "$repo", 'at the root before' );
  is( $evals[1], "$wt", 'in the worktree after enter_worktree' );
  is( $evals[2], $repo->child('.raider/worktrees/agent-1')->stringify, 'an isolated subagent in its own worktree' );
};

subtest 'hook inputs: cwd is the working root; the hook runs at the root, CLAUDE_PROJECT_DIR stays' => sub {
  my $out = tmpdir();
  my $repo = git_repo(
    '.claude/settings.json' => $json->encode({ hooks => { PreToolUse => [ { matcher => 'Read', hooks => [
      { type => 'command', command => 'cat >> '.$out.'/inputs.jsonl; echo >> '.$out.'/inputs.jsonl;'
        .' echo "$(pwd) $CLAUDE_PROJECT_DIR" >> '.$out.'/where' } ] } ] } }),
    'a.txt' => "a\n",
  );
  my $app = app_in( $repo, { claude => 1 },
    { tool_calls => [ [ read_file => { path => 'a.txt' } ] ] },
    { tool_calls => [ [ enter_worktree => {} ] ] },
    { tool_calls => [ [ read_file => { path => 'a.txt' } ] ] },
    { tool_calls => [ [ agent => { description => 'Iso', prompt => 'Read it.', isolation => 'worktree' } ] ] },
    { tool_calls => [ [ read_file => { path => 'a.txt' } ] ] },
    { text => 'read' },
    { text => 'done' },
  );
  ok( $app->context->claude_layout, 'the Claude layout' );
  $app->run('go');
  my @in = map { $json->decode($_) } grep { /\S/ } $out->child('inputs.jsonl')->lines_raw;
  my $wt  = $repo->child('.claude/worktrees/session-1');
  my $iso = $repo->child('.claude/worktrees/agent-1');
  is( [ map { $_->{cwd} } @in ], [ "$repo", "$wt", "$iso" ], 'cwd: the root, the worktree, the isolated agent\'s worktree' );
  is( [ map { $_->{tool_input}{file_path} } @in ], [ "$repo/a.txt", "$wt/a.txt", "$iso/a.txt" ],
    'a relative file_path is made absolute against that cwd' );
  is( [ $out->child('where')->lines({ chomp => 1 }) ], [ ( "$repo $repo" ) x 3 ],
    'the hook process runs at the root with CLAUDE_PROJECT_DIR the root, every time' );
};

done_testing;
