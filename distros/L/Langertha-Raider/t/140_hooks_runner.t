#!/usr/bin/env perl
# ABSTRACT: The Claude Code hook runner: matchers, processes, stdin/stdout JSON, merging (k155)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use IO::Async::Loop;
use JSON::MaybeXS ();
use Path::Tiny;
use Time::HiRes ();
use Langertha::Raider::Context::Plugins;
use Langertha::Raider::Context::Settings;
use Langertha::Raider::Hooks;

# Fake hooks are small sh scripts in a temp dir; they write what they saw
# (stdin, argv, env, cwd) into files there. HOME and CLAUDE_CONFIG_DIR point
# at temp dirs, so the real ~/.claude is never read.

my $home = path(tempdir(CLEANUP => 1));
local $ENV{HOME} = "$home";
local $ENV{CLAUDE_CONFIG_DIR} = '';
local $ENV{CLAUDE_PLUGIN_ROOT} = '/inherited/root';   # must not reach settings hooks

my $loop = IO::Async::Loop->new;
my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $T = JSON::MaybeXS->true;
my $F = JSON::MaybeXS->false;

my $bin  = path(tempdir(CLEANUP => 1));
my $root = path(tempdir(CLEANUP => 1));
$root->child('lib')->mkpath;

sub spew_json { my ( $file, $data ) = @_; path($file)->parent->mkpath; path($file)->spew_raw($json->encode($data)) }

my $n = 0;
sub script {
  my ( $body ) = @_;
  my $file = $bin->child('hook'.++$n);
  $file->spew_raw("#!/bin/sh\n".$body."\n");
  $file->chmod(0755);
  return "$file";
}

# A hook that prints a JSON answer.
sub answer { my ( $data, $exit ) = @_; script("cat >/dev/null\nprintf '%s' '".$json->encode($data)."'\nexit ".( $exit // 0 )) }

sub group { my ( $matcher, @hooks ) = @_; { matcher => $matcher, hooks => [ map { ref $_ ? $_ : { type => 'command', command => $_ } } @hooks ], source => 'test', plugin => undef } }

sub runner { Langertha::Raider::Hooks->new( loop => $loop, root => "$root", @_ ) }

sub ran { my ( $r ) = @_; [ map { $_->{command} } grep { $_->{outcome} ne 'skipped' } @{ $r->runs } ] }

sub wait_until {
  my ( $cond, $secs ) = @_;
  my $end = Time::HiRes::time() + ( $secs // 10 );
  $loop->loop_once(0.05) until $cond->() || Time::HiRes::time() > $end;
  return $cond->();
}

subtest 'matchers' => sub {
  my %c = map { $_ => answer({}) } qw( bash editwrite edit_re star empty none mcp list );
  my $h = runner( groups => { PreToolUse => [
    group( 'Bash', $c{bash} ),
    group( 'Edit|Write', $c{editwrite} ),
    group( '^Ed.*', $c{edit_re} ),
    group( '*', $c{star} ),
    group( '', $c{empty} ),
    group( undef, $c{none} ),
    group( 'mcp__memory__.*', $c{mcp} ),
    group( ' Write , Edit ', $c{list} ),
    group( '(', answer({}) ),
  ] } );

  my $r = $h->run( PreToolUse => { tool_name => 'bash', tool_input => { command => 'ls' } } );
  is( ran($r), [ @c{qw( bash star empty none )} ], 'bash is Bash; *, empty and none match all' );
  is( scalar @{ $r->errors }, 1, 'the invalid regex is reported' );
  like( $r->errors->[0], qr/invalid matcher "\(" in test, group skipped/, '... with the matcher and its source' );

  $r = $h->run( PreToolUse => { tool_name => 'edit_file', tool_input => { path => 'a' } } );
  is( ran($r), [ @c{qw( editwrite edit_re star empty none list )} ], 'edit_file is Edit: list, regex and spaced list' );

  $r = $h->run( PreToolUse => { tool_name => 'mcp__memory__create', tool_input => {} } );
  is( ran($r), [ @c{qw( star empty none mcp )} ], 'mcp__ names unchanged' );

  $r = $h->run( PreToolUse => { tool_name => 'perl_eval', tool_input => {} } );
  is( ran($r), [ @c{qw( star empty none )} ], 'a raider-only tool keeps its name, matches only match-all' );

  my $s = runner( groups => {
    SessionStart     => [ group( 'startup|resume', $c{bash} ), group( 'clear', $c{star} ) ],
    UserPromptSubmit => [ group( 'NeverMatches', $c{none} ) ],
    SubagentStart    => [ group( '^my-plugin:reviewer$', $c{mcp} ), group( 'Explore', $c{list} ) ],
  } );
  is( ran( $s->run( SessionStart => { source => 'resume' } ) ), [ $c{bash} ], 'SessionStart matches the source' );
  is( ran( $s->run( SessionStart => { source => 'clear' } ) ), [ $c{star} ], '... clear' );
  is( ran( $s->run( UserPromptSubmit => { prompt => 'x' } ) ), [ $c{none} ], 'UserPromptSubmit ignores the matcher' );
  is( ran( $s->run( SubagentStart => { agent_type => 'my-plugin:reviewer' } ) ), [ $c{mcp} ], 'SubagentStart matches agent_type' );
  ok( $s->has_hooks('SessionStart'), 'has_hooks' );
  ok( !$s->has_hooks('Stop'), 'has_hooks: none' );
  is( $s->run( Stop => {} )->runs, [], 'no hooks: empty result' );
};

subtest 'stdin, cwd, environment' => sub {
  my $seen = $bin->child('seen');
  my $cmd = script(qq{cat > "$seen/stdin.json"\npwd > "$seen/cwd"\nenv > "$seen/env"});
  $seen->mkpath;
  my $h = runner( project_dir => '/the/project', groups => { map { $_ => [ group( undef, $cmd ) ] } qw( PreToolUse PostToolUse ) } );
  my $r = $h->run( PreToolUse => {
    session_id      => 's1',
    transcript_path => '/t.jsonl',
    permission_mode => 'default',
    tool_name       => 'edit_file',
    tool_input      => { path => 'lib/A.pm', old_string => 'a', new_string => 'b' },
    tool_use_id     => 'c1',
  } );
  is( $r->runs->[0]{outcome}, 'success', 'ran' );
  is( $json->decode( $seen->child('stdin.json')->slurp_raw ), {
    session_id      => 's1',
    transcript_path => '/t.jsonl',
    permission_mode => 'default',
    cwd             => "$root",
    hook_event_name => 'PreToolUse',
    tool_name       => 'Edit',
    tool_input      => { file_path => "$root/lib/A.pm", old_string => 'a', new_string => 'b' },
    tool_use_id     => 'c1',
  }, 'Claude Code input: Claude name, Claude form, absolute file_path' );
  is( $seen->child('cwd')->slurp =~ s/\n\z//r, path("$root")->realpath->stringify, 'runs in root' );
  my %env = map { split /=/, $_, 2 } grep { /=/ } split /\n/, $seen->child('env')->slurp;
  is( $env{CLAUDE_PROJECT_DIR}, '/the/project', 'CLAUDE_PROJECT_DIR' );
  ok( !exists $env{CLAUDE_PLUGIN_ROOT}, 'no inherited CLAUDE_PLUGIN_ROOT for a settings hook' );

  $r = $h->run( PostToolUse => { tool_name => 'bash', tool_input => { command => 'ls', timeout => 5 }, tool_response => { stdout => 'x' } } );
  my $in = $json->decode( $seen->child('stdin.json')->slurp_raw );
  is( [ @$in{qw( hook_event_name tool_name )} ], [qw( PostToolUse Bash )], 'PostToolUse' );
  is( $in->{tool_input}, { command => 'ls', timeout => 5000 }, 'bash timeout in milliseconds' );
  is( $in->{tool_response}, { stdout => 'x' }, 'tool_response as given' );
};

subtest 'exec form and shell form' => sub {
  my $out = $bin->child('argv');
  my $echo = script(qq{for a in "\$@"; do echo "[\$a]"; done > "$out"});
  my $h = runner( groups => {
    Stop => [ group( undef, { type => 'command', command => $echo, args => [ 'a b', q{it's}, '$HOME', '${CLAUDE_PROJECT_DIR}/x' ] } ) ],
  } );
  my $r = $h->run( Stop => {} );
  is( $r->runs->[0]{form}, 'exec', 'args: exec form' );
  is( [ split /\n/, $out->slurp ], [ '[a b]', q{[it's]}, '[$HOME]', "[$root/x]" ],
    'each element one argument, verbatim, placeholders replaced' );

  my $file = $bin->child('shell');
  $h = runner( groups => { Stop => [ group( undef, qq{echo \$((1+2)) "\$CLAUDE_PROJECT_DIR" > "$file"} ) ] } );
  $r = $h->run( Stop => {} );
  is( $r->runs->[0]{form}, 'shell', 'no args: shell form' );
  is( $r->runs->[0]{argv}[0], 'sh', 'sh -c' );
  is( $file->slurp, "3 $root\n", 'the shell interprets it, the env has CLAUDE_PROJECT_DIR' );

  $h = runner( groups => { Stop => [ group( undef, { type => 'command', command => 'no-such-hook-command-x', args => [] } ) ] } );
  $r = $h->run( Stop => {} );
  is( $r->runs->[0]{exit}, 127, 'a command that cannot start exits 127' );
  like( $r->errors->[0], qr/\AStop hook error: \[no-such-hook-command-x\]: Failed with non-blocking status code: cannot run/, 'non-blocking error' );
};

subtest 'plugin hooks: variables and data dir' => sub {
  my $plugin_root = path(tempdir(CLEANUP => 1));
  my $data = $home->child('.claude/plugins/data/p-m');
  my $out = $bin->child('plugin-out');
  $plugin_root->child('hooks')->mkpath;
  my $script = $plugin_root->child('hooks/run');
  $script->spew_raw(qq{#!/bin/sh\necho "\$1|\$CLAUDE_PLUGIN_ROOT|\$CLAUDE_PLUGIN_DATA|\$CLAUDE_PROJECT_DIR" > "$out"\n});
  $script->chmod(0755);
  my $h = runner( groups => { SessionStart => [ {
    matcher => undef,
    hooks   => [ { type => 'command', command => '${CLAUDE_PLUGIN_ROOT}/hooks/run', args => [ '${CLAUDE_PLUGIN_DATA}' ] } ],
    source  => 'plugin:p',
    plugin  => { name => 'p', key => 'p@m', root => "$plugin_root", data_dir => "$data" },
  } ] } );
  my $r = $h->run( SessionStart => { source => 'startup' } );
  is( $r->runs->[0]{outcome}, 'success', 'ran' );
  is( $r->runs->[0]{plugin}, 'p', 'plugin name in the report' );
  is( $out->slurp, "$data|$plugin_root|$data|$root\n", 'placeholders and environment' );
  ok( -d $data, 'the data dir is created' );
};

subtest 'PreToolUse decisions' => sub {
  my $allow = answer({ hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'allow', permissionDecisionReason => 'fine' } });
  my $ask   = answer({ hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'ask', permissionDecisionReason => 'sure?' } });
  my $deny  = answer({ hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'deny', permissionDecisionReason => 'no way' } });
  my $deny2 = script("cat >/dev/null\necho 'Blocked: rm' >&2\nexit 2");
  my $call = { tool_name => 'bash', tool_input => { command => 'rm -rf x' } };

  my $r = runner( groups => { PreToolUse => [ group( 'Bash', $allow, $ask ) ] } )->run( PreToolUse => $call );
  is( [ $r->decision, $r->reasons ], [ 'ask', ['sure?'] ], 'ask beats allow; its reason' );

  $r = runner( groups => { PreToolUse => [ group( 'Bash', $allow, $deny, $ask, $deny2 ) ] } )->run( PreToolUse => $call );
  is( $r->decision, 'deny', 'deny beats all' );
  is( $r->reasons, [ 'no way', 'Blocked: rm' ], 'deny reasons in configuration order, exit 2 gives stderr' );
  is( $r->reason, "no way\nBlocked: rm", 'reason' );

  $r = runner( groups => { PreToolUse => [ group( 'Bash', answer({ decision => 'block', reason => 'old style' }) ) ] } )->run( PreToolUse => $call );
  is( [ $r->decision, $r->reason ], [ 'deny', 'old style' ], 'deprecated decision block is deny' );

  $r = runner( groups => { PreToolUse => [ group( 'Bash', answer({ hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'deny', permissionDecisionReason => 'json says' } }, 1) ) ] } )->run( PreToolUse => $call );
  is( $r->decision, 'deny', 'exit 1 with a valid JSON answer: the fields decide' );

  $r = runner( groups => { PreToolUse => [ group( 'Bash', answer({ hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'allow' } }, 2) ) ] } )->run( PreToolUse => $call );
  is( $r->decision, 'deny', 'exit 2 blocks even when the JSON allows' );

  $r = runner( groups => { PreToolUse => [ group( 'Bash', answer({ hookSpecificOutput => { hookEventName => 'PostToolUse', permissionDecision => 'deny' } }) ) ] } )->run( PreToolUse => $call );
  is( $r->decision, undef, 'hookEventName for another event: no decision' );
  like( $r->errors->[0], qr/hookEventName is "PostToolUse", not "PreToolUse"/, '... a non-blocking error' );

  $r = runner( groups => { PreToolUse => [ group( 'Bash', script("cat >/dev/null\necho 'just text'") ) ] } )->run( PreToolUse => $call );
  is( [ $r->decision, $r->additional_context, $r->errors ], [ undef, [], [] ], 'plain text on PreToolUse: nothing' );
};

subtest 'exit codes and plain output on other events' => sub {
  my $r = runner( groups => { UserPromptSubmit => [ group( undef, script("cat >/dev/null\necho 'branch: main'") ) ] } )
    ->run( UserPromptSubmit => { prompt => 'hi' } );
  is( $r->additional_context, ['branch: main'], 'plain stdout is context on UserPromptSubmit' );

  $r = runner( groups => { SessionStart => [ group( undef, script("cat >/dev/null\necho ctx") ) ] } )->run( SessionStart => { source => 'startup' } );
  is( $r->context, 'ctx', '... and on SessionStart' );

  $r = runner( groups => { UserPromptSubmit => [ group( undef, script("cat >/dev/null\necho 'no secrets' >&2\nexit 2") ) ] } )
    ->run( UserPromptSubmit => { prompt => 'hi' } );
  is( [ $r->blocked, $r->reasons ], [ 1, ['no secrets'] ], 'exit 2 blocks the prompt, stderr is the reason' );

  $r = runner( groups => { UserPromptSubmit => [ group( undef, answer({ decision => 'block', reason => 'nope', hookSpecificOutput => { hookEventName => 'UserPromptSubmit', additionalContext => 'more' } }) ) ] } )
    ->run( UserPromptSubmit => { prompt => 'hi' } );
  is( [ $r->blocked, $r->reasons, $r->additional_context ], [ 1, ['nope'], ['more'] ], 'decision block with reason and context' );

  $r = runner( groups => { SessionStart => [ group( undef, script("cat >/dev/null\necho 'boom' >&2\nexit 2") ) ] } )->run( SessionStart => { source => 'startup' } );
  ok( !$r->blocked, 'SessionStart cannot block' );
  like( $r->errors->[0], qr/\ASessionStart hook error: \[.+\]: boom\z/, 'exit 2 there is a non-blocking error' );

  $r = runner( groups => { Stop => [ group( undef, script("cat >/dev/null\necho 'x: No such file or directory' >&2\nexit 2") ) ] } )->run( Stop => {} );
  ok( !$r->blocked, 'Stop: exit 2 for a missing file does not block' );
  is( scalar @{ $r->errors }, 1, '... it is an error' );

  $r = runner( groups => { Stop => [ group( undef, script("cat >/dev/null\necho 'run the tests first' >&2\nexit 2") ) ] } )->run( Stop => { stop_hook_active => $F } );
  is( [ $r->blocked, $r->reasons ], [ 1, ['run the tests first'] ], 'Stop: exit 2 keeps going with the reason' );

  $r = runner( groups => { PostToolUse => [ group( undef, script("cat >/dev/null\necho 'something broke' >&2\necho 'second' >&2\nexit 1") ) ] } )
    ->run( PostToolUse => { tool_name => 'bash', tool_input => { command => 'ls' } } );
  is( $r->errors, [ 'PostToolUse:Bash hook error: ['.$r->runs->[0]{command}.']: Failed with non-blocking status code: something broke' ],
    'exit 1: non-blocking error with the first stderr line' );
  ok( !$r->blocked, 'not blocked' );

  $r = runner( groups => { PostToolUse => [ group( undef, script("cat >/dev/null\necho '{oops}'") ) ] } )
    ->run( PostToolUse => { tool_name => 'bash', tool_input => {} } );
  like( $r->errors->[0], qr/stdout is not valid JSON/, 'invalid JSON: non-blocking error' );

  $r = runner( groups => { Stop => [ group( undef, answer({ continue => $F, stopReason => 'build failed', systemMessage => 'look' }), answer({ continue => $F, stopReason => 'second' }) ) ] } )
    ->run( Stop => {} );
  is( [ $r->stopped, $r->stop_reason, $r->system_messages ], [ 1, 'build failed', ['look'] ], 'continue false: stopped, first stopReason' );
};

subtest 'updatedInput is translated back and merged' => sub {
  my $call = { tool_name => 'edit_file', tool_input => { path => 'lib/A.pm', old_string => 'a', new_string => 'b' } };
  my $same_path = answer({ hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'allow',
    updatedInput => { file_path => "$root/lib/A.pm", old_string => 'a', new_string => 'B', replace_all => $T } } });
  my $r = runner( groups => { PreToolUse => [ group( 'Edit', $same_path ) ] } )->run( PreToolUse => $call );
  is( $r->updated_input, { path => 'lib/A.pm', old_string => 'a', new_string => 'B', replace_all => $T },
    'raider form; the unchanged absolute path is the original relative path again' );

  my $moved = answer({ hookSpecificOutput => { hookEventName => 'PreToolUse', updatedInput => { file_path => '/elsewhere/B.pm', old_string => 'a', new_string => 'b' } } });
  $r = runner( groups => { PreToolUse => [ group( 'Edit', $same_path, $moved ) ] } )->run( PreToolUse => $call );
  is( $r->updated_input->{path}, '/elsewhere/B.pm', 'two different inputs: the last in configuration order wins' );
  like( $r->errors->[0], qr/2 hooks returned different updatedInput; the last one \(.+\) wins/, '... and that is reported' );
  is( $r->decision, 'allow', 'a hook without decision does not erase the allow' );

  my $deny = answer({ hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'deny' } });
  $r = runner( groups => { PreToolUse => [ group( 'Edit', $same_path, $deny ) ] } )->run( PreToolUse => $call );
  is( [ $r->decision, $r->updated_input ], [ 'deny', undef ], 'no updated input for a denied call' );

  $r = runner( groups => { PreToolUse => [ group( 'Bash', answer({ hookSpecificOutput => { hookEventName => 'PreToolUse', updatedInput => { command => 'ls -la', timeout => 30000 } } }) ) ] } )
    ->run( PreToolUse => { tool_name => 'bash', tool_input => { command => 'ls' } } );
  is( $r->updated_input, { command => 'ls -la', timeout => 30 }, 'bash: timeout back to seconds' );
};

subtest 'timeout' => sub {
  my $marker = $bin->child('late');
  my $slow = script(qq{cat >/dev/null\nsleep 30\ntouch "$marker"});
  my $t0 = Time::HiRes::time();
  my $r = runner( groups => { PreToolUse => [ group( undef, { type => 'command', command => $slow, timeout => 1 } ) ] } )
    ->run( PreToolUse => { tool_name => 'bash', tool_input => { command => 'ls' } } );
  my $took = Time::HiRes::time() - $t0;
  ok( $took < 10, 'did not wait for the hook (took '.sprintf('%.1f', $took).'s)' );
  is( $r->runs->[0]{outcome}, 'timeout', 'outcome timeout' );
  like( $r->errors->[0], qr/timed out after 1s, output discarded/, 'non-blocking error' );
  is( $r->decision, undef, 'a timed-out hook decides nothing' );
  ok( !-e $marker, 'the process group was stopped' );

  $r = runner( groups => { PreToolUse => [ group( undef, { type => 'command', command => $slow, timeout => 1, onFailure => 'block' } ) ] } )
    ->run( PreToolUse => { tool_name => 'bash', tool_input => { command => 'ls' } } );
  is( $r->decision, 'deny', 'onFailure block: a timeout denies' );
  like( $r->reason, qr/\Atimed out; blocking because onFailure is "block"/, '... saying why' );

  $r = runner( groups => { PreToolUse => [ group( undef, { type => 'command', command => '/no/such/script', args => [], onFailure => 'block' } ) ] } )
    ->run( PreToolUse => { tool_name => 'bash', tool_input => { command => 'ls' } } );
  is( $r->decision, 'deny', 'onFailure block: a hook that cannot start denies' );
};

subtest 'async hooks' => sub {
  my $async = script("cat >/dev/null\nsleep 1\necho 'some log line'\nprintf '%s\\n' '"
    .$json->encode({ systemMessage => 'tests ok', hookSpecificOutput => { hookEventName => 'PostToolUse', additionalContext => 'all green', permissionDecision => 'deny' } })."'");
  my $h = runner( groups => { PostToolUse => [ group( 'Write', { type => 'command', command => $async, async => $T } ) ] } );
  my $t0 = Time::HiRes::time();
  my $r = $h->run( PostToolUse => { tool_name => 'write_file', tool_input => { path => 'a', content => 'x' } } );
  ok( Time::HiRes::time() - $t0 < 0.9, 'run_f does not wait for an async hook' );
  is( $r->runs->[0]{outcome}, 'running', 'reported as running' );
  is( $r->runs->[0]{timeout}, undef, 'no timeout' );
  is( $h->running_async, 1, 'one async hook running' );
  is( [ $h->take_async_results ], [], 'nothing finished yet' );
  ok( wait_until( sub { !$h->running_async } ), 'it finishes' );
  my @done = $h->take_async_results;
  is( scalar @done, 1, 'one result' );
  is( [ $done[0]->additional_context, $done[0]->system_messages, $done[0]->decision ], [ ['all green'], ['tests ok'], undef ],
    'its context and message (the JSON line among other output), no decision' );
  is( [ $h->take_async_results ], [], 'taken once' );

  my $sleeper = script("cat >/dev/null\nsleep 30");
  $h = runner( groups => { Stop => [ group( undef, { type => 'command', command => $sleeper, async => $T } ) ] } );
  $h->run( Stop => {} );
  is( $h->running_async, 1, 'running' );
  $h->shutdown->get;
  is( $h->running_async, 0, 'shutdown stops it' );
  is( ( $h->take_async_results )[0]->runs->[0]{outcome}, 'cancelled', 'cancelled' );
};

subtest 'duplicates, unsupported hooks, if rules' => sub {
  my $count = $bin->child('count');
  my $cmd = qq{cat >/dev/null; echo x >> "$count"};
  my $plugin = { name => 'p', key => 'p@m', root => "$bin", data_dir => undef };
  my $h = runner( groups => { Stop => [
    { matcher => undef, hooks => [ { type => 'command', command => $cmd } ], source => '~/.claude/settings.json', plugin => undef },
    { matcher => undef, hooks => [ { type => 'command', command => $cmd } ], source => '.claude/settings.json', plugin => undef },
    { matcher => undef, hooks => [ { type => 'command', command => $cmd } ], source => 'plugin:p', plugin => $plugin },
  ] } );
  my $r = $h->run( Stop => {} );
  is( scalar( () = $count->lines ), 2, 'same command from two settings files once, the plugin copy separately' );
  is( [ map { $_->{outcome} } @{ $r->runs } ], [qw( success skipped success )], 'the duplicate is reported as skipped' );

  my $ok = answer({});
  $h = runner( groups => {
    Stop       => [ group( undef, { type => 'http', url => 'http://x' }, { type => 'command', command => $ok, if => 'Bash(*)' } ) ],
    PreToolUse => [ group( undef, { type => 'command', command => $ok, if => 'Bash(git *)' } ) ],
  } );
  $r = $h->run( Stop => {} );
  is( [ map { $_->{message} } @{ $r->runs } ], [ 'hook type "http" is not supported, only "command"', '"if" applies to tool events only' ],
    'http skipped; if on a non-tool event never runs' );
  $r = $h->run( PreToolUse => { tool_name => 'bash', tool_input => { command => 'ls' } } );
  ok( $r->runs->[0]{if_unchecked}, 'without if_matcher the hook runs, marked unchecked' );

  my @asked;
  my $with = runner( groups => $h->groups, if_matcher => sub { push @asked, [@_]; $_[1]{arguments}{command} =~ /\Agit / } );
  $r = $with->run_f( PreToolUse => { tool_name => 'bash', tool_input => { command => 'ls' } }, tool_source => 'engine:2' )->get;
  is( $r->runs->[0]{outcome}, 'skipped', 'if_matcher says no: skipped' );
  is( $asked[0], [ 'Bash(git *)', { name => 'bash', source => 'engine:2', arguments => { command => 'ls' } } ],
    'the matcher gets the rule and the raider call with its source' );
  $r = $with->run( PreToolUse => { tool_name => 'bash', tool_input => { command => 'git push' } } );
  is( $r->runs->[0]{outcome}, 'success', 'if_matcher says yes: runs' );
  $r = runner( groups => $h->groups, if_matcher => sub { undef } )->run( PreToolUse => { tool_name => 'bash', tool_input => { command => 'ls' } } );
  is( [ $r->runs->[0]{outcome}, $r->runs->[0]{if_unchecked} ], [ 'success', 1 ], 'if_matcher cannot tell: runs, unchecked' );
};

subtest 'native briefing skips briefing-preload where it would load twice' => sub {
  my $preload = $bin->child('plugin/hooks/briefing-preload');
  $preload->parent->mkpath;
  $preload->spew_raw("#!/bin/sh\ncat >/dev/null\n");
  $preload->chmod(0755);
  my $plugin = { name => 'briefing', key => 'briefing@getty', root => $bin->child('plugin')->stringify, data_dir => undef };
  my $hook = { type => 'command', command => '${CLAUDE_PLUGIN_ROOT}/hooks/briefing-preload', args => [] };
  my %groups = map { $_ => [ { matcher => ( $_ eq 'PreToolUse' ? 'Agent' : undef ), hooks => [$hook], source => 'plugin:briefing', plugin => $plugin } ] }
    qw( PreToolUse SubagentStart SessionStart );
  my $agent = { tool_name => 'agent', tool_input => { prompt => 'p', subagent_type => 'x' } };

  my $off = runner( groups => \%groups );
  is( $off->run( PreToolUse => $agent )->runs->[0]{outcome}, 'success', 'default: the hook runs' );

  my $on = runner( groups => \%groups, native_briefing => 1 );
  my $r = $on->run( PreToolUse => $agent );
  is( $r->runs->[0]{outcome}, 'skipped', 'native: skipped on PreToolUse Agent' );
  like( $r->runs->[0]{message}, qr/native_briefing/, '... saying why' );
  is( $on->run( SubagentStart => { agent_type => 'x' } )->runs->[0]{outcome}, 'skipped', '... and on SubagentStart' );
  is( $on->run( SessionStart => { source => 'startup' } )->runs->[0]{outcome}, 'success', 'its SessionStart check still runs' );
};

subtest 'collected from settings and enabled plugins' => sub {
  my $proj = path(tempdir(CLEANUP => 1));
  my $claude = $home->child('.claude');
  my $out = $bin->child('collected');
  my $make_plugin = sub {
    my ( $name ) = @_;
    my $r = $claude->child('plugins/cache/m/'.$name.'/1.0');
    my $s = $r->child('hooks/run');
    $s->parent->mkpath;
    $s->spew_raw(qq{#!/bin/sh\ncat >/dev/null\necho "$name \$1" >> "$out"\n});
    $s->chmod(0755);
    return $r;
  };
  my $on  = $make_plugin->('onp');
  my $off = $make_plugin->('offp');
  spew_json( $on->child('hooks/hooks.json'), { hooks => { SessionStart => [ { hooks => [ { type => 'command', command => '${CLAUDE_PLUGIN_ROOT}/hooks/run', args => ['file'] } ] } ] } } );
  spew_json( $on->child('.claude-plugin/plugin.json'), { name => 'onp', hooks => [
    { SessionStart => [ { matcher => 'startup', hooks => [ { type => 'command', command => '${CLAUDE_PLUGIN_ROOT}/hooks/run', args => ['inline'] } ] } ] },
    './extra.json', '../escape.json', './hooks/hooks.json',
  ] } );
  spew_json( $on->child('extra.json'), { SessionStart => [] } );   # no "hooks" wrapper
  spew_json( $off->child('hooks/hooks.json'), { hooks => { SessionStart => [ { hooks => [ { type => 'command', command => '${CLAUDE_PLUGIN_ROOT}/hooks/run', args => ['off'] } ] } ] } } );
  spew_json( $claude->child('plugins/installed_plugins.json'), { version => 2, plugins => {
    'onp@m'  => [ { scope => 'user', installPath => "$on" } ],
    'offp@m' => [ { scope => 'user', installPath => "$off" } ],
  } } );
  spew_json( $claude->child('settings.json'), {
    enabledPlugins => { 'onp@m' => $T, 'offp@m' => $F },
    hooks => { SessionStart => [ { matcher => 'startup', hooks => [ { type => 'command', command => qq{cat >/dev/null; echo settings >> "$out"} } ] } ] },
  } );

  my $settings = Langertha::Raider::Context::Settings->new( project_dir => "$proj" );
  my $plugins = Langertha::Raider::Context::Plugins->new( cwd => "$proj", enabled => $settings->enabled_plugin_map );
  my $h = runner( settings => $settings, plugins => $plugins );
  is( [ map { $_->{source} } @{ $h->groups->{SessionStart} } ], [ '~/.claude/settings.json', 'plugin:onp', 'plugin:onp' ],
    'settings first, then the plugin: hooks.json, then the manifest; the disabled plugin is not there' );
  is( $h->groups->{SessionStart}[1]{plugin}{data_dir}, $claude->child('plugins/data/onp-m')->stringify, 'data dir from the key' );
  is( [ sort @{ $h->config_errors } ], [
    'plugin:onp: ../escape.json is outside the plugin',
    'plugin:onp: ./extra.json has no "hooks" object',
  ], 'broken hook files are reported; hooks.json named twice counts once' ) or diag $json->encode($h->config_errors);
  $h->run( SessionStart => { source => 'startup' } );
  is( [ sort $out->lines({ chomp => 1 }) ], [ 'onp file', 'onp inline', 'settings' ], 'all three ran' );

  spew_json( $proj->child('.claude/settings.json'), { disableAllHooks => $T } );
  $settings = Langertha::Raider::Context::Settings->new( project_dir => "$proj" );
  $h = runner( settings => $settings, plugins => Langertha::Raider::Context::Plugins->new( cwd => "$proj", enabled => $settings->enabled_plugin_map ) );
  is( $h->groups, {}, 'disableAllHooks: no hooks at all' );
  $claude->child('settings.json')->remove;
};

done_testing;
