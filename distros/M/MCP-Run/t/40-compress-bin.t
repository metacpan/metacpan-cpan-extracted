use strict;
use warnings;
use Test::More;
use lib 'lib';
use IPC::Open3 qw( open3 );
use Symbol        qw( gensym );
use JSON::MaybeXS ();
use Path::Tiny    qw( path tempdir );

# Coverage for bin/mcp-run-compress: the PreToolUse hook (Co-Authored-By,
# no-compress marker, bypasses), the PostToolUse hook (compression through
# updatedToolOutput, persisted output, byte cap, bypasses), fail-open on a
# broken install, and --install-claude including the migration of an
# installation from before the PostToolUse move.

my $bin = path($0)->parent->parent->child('bin', 'mcp-run-compress');
ok(-x $bin, "bin/mcp-run-compress is executable: $bin") or BAIL_OUT("binary missing");
my $lib_path = path($0)->parent->parent->child('lib')->realpath;
my @keep_alive;    # tempdirs that must outlive the subtest that made them

my $MARKER = '# mcp-run-compress: no-compress';

# -------------------------------------------------------------------------
# PreToolUse — no longer rewrites the command for compression
# -------------------------------------------------------------------------
subtest 'pre: plain command is not rewritten at all' => sub {
  my ($stdout, $stderr, $rc) = run_hook($bin, pre_payload('ls -la'));
  is $rc, 0, 'hook exit 0';

  my $resp = decode_json($stdout);
  is $resp->{hookSpecificOutput}{hookEventName}, 'PreToolUse', 'hookEventName PreToolUse';
  ok !exists $resp->{hookSpecificOutput}{updatedInput},
    'command untouched — compression no longer happens by rewriting it';
};

subtest 'pre: Co-Authored-By rewrite still happens before the command runs' => sub {
  local $ENV{CO_AUTHORED_BY} = 'Claude Opus 5 <noreply@anthropic.com>';
  local $ENV{MCP_RUN_COMPRESS_NO_CO_AUTHORED} = '';

  my ($stdout, $stderr, $rc) = run_hook($bin, pre_payload('git commit -m "x"'));
  my $cmd = decode_json($stdout)->{hookSpecificOutput}{updatedInput}{command};

  like $cmd, qr/\QCo-Authored-By: Claude Opus 5 <noreply\E/,
    'trailer injected — this is why PreToolUse still exists';
  like $cmd, qr/\Agit commit -m/, 'still the same command';
};

subtest 'pre: bypasses background commands' => sub {
  my $in = encode_json({
    hook_event_name => 'PreToolUse',
    tool_input      => { command => 'sleep 10', run_in_background => JSON::MaybeXS::true() },
  });
  my ($stdout, $stderr, $rc) = run_hook($bin, $in);
  ok !exists decode_json($stdout)->{hookSpecificOutput}{updatedInput},
    'background command not touched';
};

subtest 'pre: naming this tool does not cost you the commit trailer' => sub {
  # The whole point of karr #26. PreToolUse stopped rewriting commands, so a
  # self-bypass on the tool's own name no longer suppresses a rewrite — it
  # suppresses the Co-Authored-By trailer, and in this repository a commit
  # message naming mcp-run-compress is the normal case.
  local $ENV{CO_AUTHORED_BY} = 'Claude Opus 5 <noreply@anthropic.com>';
  local $ENV{MCP_RUN_COMPRESS_NO_CO_AUTHORED} = '';

  my ($stdout, $stderr, $rc) = run_hook($bin,
    pre_payload('git commit -m "Fix mcp-run-compress hook"'));
  my $cmd = decode_json($stdout)->{hookSpecificOutput}{updatedInput}{command};

  like $cmd, qr/\QCo-Authored-By: Claude Opus 5\E/,
    'trailer injected even though the message names the tool';
  like $cmd, qr/\QFix mcp-run-compress hook\E/, 'message itself untouched';
};

subtest 'pre: an ordinary non-git command is still left alone' => sub {
  # Nothing to transform and no prefix to strip: the hook must stay out of
  # the way rather than claim an updatedInput identical to its input.
  for my $command ('mcp-run-compress --hook', 'grep -rn mcp-run-compress .', 'ls -la') {
    my ($stdout, $stderr, $rc) = run_hook($bin, pre_payload($command));
    ok !exists decode_json($stdout)->{hookSpecificOutput}{updatedInput},
      "not touched: $command";
  }
};

subtest 'pre: no-compress controls compression, not the commit policy' => sub {
  # `no-compress` means "do not compress the output". It never meant "skip
  # the Co-Authored-By trailer", and the two must not ride on one flag.
  local $ENV{CO_AUTHORED_BY} = 'Claude Opus 5 <noreply@anthropic.com>';
  local $ENV{MCP_RUN_COMPRESS_NO_CO_AUTHORED} = '';

  my ($stdout, $stderr, $rc) = run_hook($bin,
    pre_payload('no-compress git commit -m "x"'));
  my $cmd = decode_json($stdout)->{hookSpecificOutput}{updatedInput}{command};

  like $cmd, qr/\QCo-Authored-By: Claude Opus 5\E/, 'trailer still injected';
  like $cmd, qr/\Q$MARKER\E\z/, 'and the bypass marker is the last line';
  unlike $cmd, qr/\Ano-compress /, 'prefix stripped';

  # Both jobs done, and in an order bash accepts: the trailer lives inside
  # the quoted commit message, the marker is a comment after it.
  my (undef, undef, $bash_rc) = run(['bash', '-n', '-c', $cmd]);
  is $bash_rc, 0, 'the combined rewrite still parses as bash';
};

subtest 'pre: MCP_RUN_COMPRESS_NO_CO_AUTHORED is the one way to suppress it' => sub {
  local $ENV{CO_AUTHORED_BY} = 'Claude Opus 5 <noreply@anthropic.com>';
  local $ENV{MCP_RUN_COMPRESS_NO_CO_AUTHORED} = 1;

  for my $command ('git commit -m "x"', 'git commit -m "x mcp-run-compress y"') {
    my ($stdout, $stderr, $rc) = run_hook($bin, pre_payload($command));
    ok !exists decode_json($stdout)->{hookSpecificOutput}{updatedInput},
      "documented opt-out honoured: $command";
  }
};

subtest 'pre: a background git commit still gets its trailer' => sub {
  # The background bypass is about compression — the output of a background
  # command cannot be compressed. The commit policy is a different question.
  local $ENV{CO_AUTHORED_BY} = 'Claude Opus 5 <noreply@anthropic.com>';
  local $ENV{MCP_RUN_COMPRESS_NO_CO_AUTHORED} = '';

  my $in = encode_json({
    hook_event_name => 'PreToolUse',
    tool_input      => {
      command           => 'git commit -m "x"',
      run_in_background => JSON::MaybeXS::true(),
    },
  });
  my ($stdout, $stderr, $rc) = run_hook($bin, $in);
  my $cmd = decode_json($stdout)->{hookSpecificOutput}{updatedInput}{command};

  like $cmd, qr/\QCo-Authored-By: Claude Opus 5\E/, 'trailer applied';

  # And the other half: a background command that DID ask for the bypass
  # still gets its prefix stripped — leaving `no-compress` in place would
  # break the command — but no marker, since nothing will read it.
  my $bg = encode_json({
    hook_event_name => 'PreToolUse',
    tool_input      => {
      command           => 'no-compress ls -la',
      run_in_background => JSON::MaybeXS::true(),
    },
  });
  ($stdout, $stderr, $rc) = run_hook($bin, $bg);
  is decode_json($stdout)->{hookSpecificOutput}{updatedInput}{command}, 'ls -la',
    'prefix stripped, no marker — background output is never compressed';
};

subtest 'pre: malformed input still returns a well-formed response' => sub {
  my ($stdout, $stderr, $rc) = run_hook($bin, 'not json at all');
  is $rc, 0, 'exit 0';
  my $resp = decode_json($stdout);
  is $resp->{hookSpecificOutput}{hookEventName}, 'PreToolUse',
    'hookEventName set even with malformed input';
  ok !exists $resp->{hookSpecificOutput}{updatedInput}, 'no rewrite on malformed input';
};

# -------------------------------------------------------------------------
# The no-compress marker
#
# PostToolUse is shown the command as PreToolUse rewrote it, never the
# user's original, so a prefix that PreToolUse strips is invisible by the
# time compression happens. The bypass rides along inside the command.
# -------------------------------------------------------------------------
subtest 'pre: no-compress prefix becomes a trailing marker comment' => sub {
  my ($stdout, $stderr, $rc) = run_hook($bin, pre_payload('no-compress ls -la'));
  my $cmd = decode_json($stdout)->{hookSpecificOutput}{updatedInput}{command};

  is $cmd, "ls -la\n$MARKER", 'prefix stripped, marker appended as its own line';
};

subtest 'marker: appending it does not change what bash does' => sub {
  # The load-bearing claim behind the whole bypass. If a marker can change
  # a command's behaviour, the bypass is worse than no bypass.
  my @shapes = (
    ['simple',            'echo foo'],
    ['multiline',         "echo a\necho b"],
    ['trailing newline',  "echo a\necho b\n"],
    ['heredoc',           "cat <<EOF\nhello\nEOF"],
    ['heredoc quoted',    "cat <<'EOF'\nhello \$x\nEOF"],
    ['heredoc dash',      "cat <<-EOF\n\thello\n\tEOF"],
    ['two heredocs',      "cat <<A; cat <<B\n1\nA\n2\nB"],
    ['function',          "f() { echo hi; }\nf"],
    ['if block',          "if true; then\n echo yes\nfi"],
    ['case block',        "case x in\n x) echo m ;;\nesac"],
    ['while loop',        "i=0\nwhile [ \$i -lt 2 ]; do echo \$i; i=\$((i+1)); done"],
    ['subshell',          "(\n echo s\n)"],
    ['line continuation', "echo foo \\\n bar"],
    ['background job',    'echo bg & wait'],
    ['non-zero exit',     'echo x; exit 3'],
    ['trailing comment',  "echo a\n# already a comment"],
  );

  for my $shape (@shapes) {
    my ($name, $cmd) = @$shape;
    my @plain  = run(['bash', '-c', $cmd]);
    my @marked = run(['bash', '-c', "$cmd\n$MARKER"]);
    is_deeply \@marked, \@plain, "$name: stdout, stderr and exit code unchanged";
  }
};

subtest 'marker: skipped on a dangling backslash rather than corrupting the command' => sub {
  # `echo foo \` + a marker line splices the comment onto the command via
  # the line continuation. Losing the bypass costs compression; losing the
  # command costs the user their work.
  my ($stdout, $stderr, $rc) = run_hook($bin, pre_payload("no-compress echo foo \\"));
  my $cmd = decode_json($stdout)->{hookSpecificOutput}{updatedInput}{command};

  is $cmd, "echo foo \\", 'prefix stripped, marker NOT appended';
  unlike $cmd, qr/\Q$MARKER\E/, 'no marker on a line-continuation command';
};

# -------------------------------------------------------------------------
# PostToolUse — the compression point
# -------------------------------------------------------------------------
subtest 'post: replaces the recorded output via updatedToolOutput' => sub {
  my $raw = "total 8\n"
    . "drwxr-xr-x  2 getty getty 4096 Apr 24 02:32 .build\n"
    . "-rw-r--r--  1 getty getty   42 Apr 24 02:32 README.md\n";

  my ($stdout, $stderr, $rc) = run_hook($bin, post_payload('ls -la', { stdout => $raw }));
  is $rc, 0, 'hook exit 0';

  my $hso = decode_json($stdout)->{hookSpecificOutput};
  is $hso->{hookEventName}, 'PostToolUse',
    'hookEventName matches the real event — a mismatch drops the whole response';

  my $updated = $hso->{updatedToolOutput};
  ok $updated, 'updatedToolOutput present';
  like $updated->{stdout}, qr/\.build/,        'entries survive';
  unlike $updated->{stdout}, qr/drwxr-xr-x/,   'ls filter stripped the permission columns';
  ok length($updated->{stdout}) < length($raw), 'output actually got smaller';
};

subtest 'post: keeps the untouched fields of the tool response' => sub {
  my ($stdout, $stderr, $rc) = run_hook($bin, post_payload('ls -la', {
    stdout      => "drwxr-xr-x 2 getty getty 4096 Apr 24 02:32 .build\n",
    stderr      => 'Shell cwd was reset',
    interrupted => JSON::MaybeXS::false(),
    isImage     => JSON::MaybeXS::false(),
  }));

  my $updated = decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput};
  is $updated->{stderr}, 'Shell cwd was reset',
    'stderr left alone — it carries harness notices, not command output';
  ok exists $updated->{interrupted}, 'interrupted survives the replacement';
  ok exists $updated->{isImage},     'isImage survives the replacement';
};

subtest 'post: no replacement when compression changes nothing' => sub {
  my ($stdout, $stderr, $rc) = run_hook($bin,
    post_payload('some-unfiltered-command', { stdout => "one line\n" }));

  ok !exists decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput},
    'no pointless claim over an output we did not improve';
};

subtest 'post: background commands are passed through' => sub {
  # The hook fires at START of a background command, so there is nothing to
  # compress yet and the response is the "running in background" notice.
  #
  # The fixtures carry filterable stdout on purpose. With empty streams the
  # bypass would be indistinguishable from the "nothing to do" exit, and a
  # test that passes with the bypass deleted proves nothing about it.
  my $filterable = "drwxr-xr-x  2 getty getty 4096 Apr 24 02:32 .build\n";

  for my $flavour (
    [ 'backgroundTaskId', { stdout => $filterable, backgroundTaskId => 'task-1' } ],
    [ 'noOutputExpected', { stdout => $filterable, noOutputExpected => JSON::MaybeXS::true() } ],
  ) {
    my ($name, $resp) = @$flavour;
    my ($stdout, $stderr, $rc) = run_hook($bin, post_payload('ls -la', $resp));
    ok !exists decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput},
      "$name: hands off, no header glued onto the background notice";
  }

  # And the shape the harness really sends: both streams empty.
  my ($stdout, $stderr, $rc) = run_hook($bin, post_payload('sleep 10', {
    stdout => '', stderr => '',
    backgroundTaskId => 'task-2', noOutputExpected => JSON::MaybeXS::true(),
  }));
  ok !exists decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput},
    'real background payload passed through';
};

subtest 'post: honours the no-compress marker left by PreToolUse' => sub {
  my $raw = "drwxr-xr-x  2 getty getty 4096 Apr 24 02:32 .build\n";
  my ($stdout, $stderr, $rc) = run_hook($bin,
    post_payload("ls -la\n$MARKER", { stdout => $raw }));

  ok !exists decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput},
    'user asked for raw output and gets it';
};

subtest 'post: marker only counts at the very end of the command' => sub {
  # A heredoc body that happens to quote the marker must not switch
  # compression off for the whole command.
  my $cmd = "cat <<EOF\n$MARKER\nEOF\nls -la";
  my $raw = "drwxr-xr-x  2 getty getty 4096 Apr 24 02:32 .build\n";
  my ($stdout, $stderr, $rc) = run_hook($bin, post_payload($cmd, { stdout => $raw }));

  ok exists decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput},
    'marker quoted mid-command does not bypass';
};

subtest 'post: self-bypass on a command that already ran through us' => sub {
  my $raw = "drwxr-xr-x  2 getty getty 4096 Apr 24 02:32 .build\n";
  my ($stdout, $stderr, $rc) = run_hook($bin,
    post_payload('mcp-run-compress --b64 bHMgLWxh', { stdout => $raw }));

  ok !exists decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput},
    'output of a stale rewrite is compressed already — not twice';
};

subtest 'post: an event we have nothing to do with is answered by name' => sub {
  # A response whose hookEventName does not match the firing event is
  # dropped silently, so guessing is not an option.
  my $in = encode_json({ hook_event_name => 'PostToolUseFailure', error => 'boom' });
  my ($stdout, $stderr, $rc) = run_hook($bin, $in);
  is $rc, 0, 'exit 0';

  my $hso = decode_json($stdout)->{hookSpecificOutput};
  is $hso->{hookEventName}, 'PostToolUseFailure', 'answers with the event that fired';
  ok !exists $hso->{updatedToolOutput},
    'nothing to replace — a failed command cannot be compressed';
};

# -------------------------------------------------------------------------
# Large output: the persisted file
# -------------------------------------------------------------------------
subtest 'post: reads persistedOutputPath and drops the persist framing' => sub {
  my $tmp  = tempdir(CLEANUP => 1);
  push @keep_alive, $tmp;
  my $file = $tmp->child('tool-result.txt');

  # 800 ls -l lines of 60 bytes: 48000 bytes, so the inline stdout really is
  # the truncated 30000 byte preview (500 lines) and the file really is the
  # only place the other 300 lines exist.
  my $full = join '', map {
    sprintf "-rw-r--r--  1 getty getty %6d Apr 24 02:32 file-%04d.txt\n", 1000 + $_, $_
  } 1 .. 800;
  $file->spew_utf8($full);
  cmp_ok length($full), '>', 30000, 'fixture is genuinely bigger than the inline cap';

  my ($stdout, $stderr, $rc) = run_hook($bin, post_payload('ls -la', {
    stdout              => substr($full, 0, 30000),
    persistedOutputPath => "$file",
    persistedOutputSize => length($full),
  }));

  my $updated = decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput};
  ok $updated, 'output replaced';

  ok !exists $updated->{persistedOutputPath},
    'persistedOutputPath deleted — this is what removes the 2KB preview framing';
  ok !exists $updated->{persistedOutputSize}, 'persistedOutputSize deleted too';

  # The ls filter keeps 50 lines and names the rest. That count is the
  # receipt for how many lines the compressor actually saw: 750 means all
  # 800, the 30000 byte preview alone would only have yielded 450.
  like $updated->{stdout}, qr/\Q... 750 more lines ...\E/,
    'the WHOLE file was compressed, not just the 30000 byte preview';
  like $updated->{stdout}, qr/\Q[mcp-run-compress:\E.*\Q$file\E/,
    'the path to the untouched original survives in the text';
  unlike $updated->{stdout}, qr/-rw-r--r--/, 'ls filter applied to the file content';
};

subtest 'post: unreadable persisted file still beats a 2KB preview' => sub {
  # Docker mode: persistedOutputPath is a HOST path the container cannot
  # see. Compress the 30000 bytes we were handed, still drop the framing,
  # and say which file was not read.
  my $preview = join '', map {
    sprintf "-rw-r--r--  1 getty getty %6d Apr 24 02:32 file-%04d.txt\n", 1000 + $_, $_
  } 1 .. 40;

  my ($stdout, $stderr, $rc) = run_hook($bin, post_payload('ls -la', {
    stdout              => $preview,
    persistedOutputPath => '/does/not/exist/here.txt',
    persistedOutputSize => 99999,
  }));

  my $updated = decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput};
  ok $updated, 'output still replaced';
  ok !exists $updated->{persistedOutputPath}, 'framing dropped anyway';
  like $updated->{stdout}, qr/not readable from here/, 'says the raw file was not read';
  like $updated->{stdout}, qr{/does/not/exist/here\.txt}, 'names it regardless';
  like $updated->{stdout}, qr/file-0040\.txt/, 'the preview itself is compressed';
};

subtest 'post: an oversized persisted file is left to the harness' => sub {
  my ($stdout, $stderr, $rc) = run_hook($bin, post_payload('ls -la', {
    stdout              => "drwxr-xr-x  2 getty getty 4096 Apr 24 02:32 .build\n",
    persistedOutputPath => '/tmp/whatever.txt',
    persistedOutputSize => 500_000_000,
  }));

  ok !exists decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput},
    'no half-gigabyte slurp inside a hook — the harness preview stands';
};

# -------------------------------------------------------------------------
# The byte cap
#
# Claude Code persists a replacement above ~30000 bytes too and shows the
# model a 2KB preview of it. Compressed output over the cap is therefore
# worse than no compression at all.
# -------------------------------------------------------------------------
subtest 'post: caps oversized output and says so' => sub {
  my $tmp  = tempdir(CLEANUP => 1);
  push @keep_alive, $tmp;
  my $file = $tmp->child('big.txt');

  # No filter matches this command, so the pipeline passes the text
  # through and the cap is the only thing between it and the model.
  my $full = join '', map { sprintf "line %05d %s\n", $_, 'x' x 60 } 1 .. 2000;
  $file->spew_utf8($full);
  cmp_ok length($full), '>', 29000, 'test input is genuinely oversized';

  my ($stdout, $stderr, $rc) = run_hook($bin, post_payload('some-unfiltered-command', {
    stdout              => substr($full, 0, 30000),
    persistedOutputPath => "$file",
    persistedOutputSize => length($full),
  }));

  my $out = decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput}{stdout};
  ok defined $out, 'output replaced';

  cmp_ok length($out), '<=', 29000,
    'stays under the cap — over it the model would see a 2KB preview instead';
  like $out, qr/\Q[mcp-run-compress:\E.*omitted/,
    'the cut is marked, not silent';
  like $out, qr/\Q$file\E/, 'and names the file holding the full text';

  like $out, qr/line 00001 /, 'head of the output kept';
  like $out, qr/line 02000 /, 'tail of the output kept';
};

subtest 'post: never cuts output the harness was willing to show inline' => sub {
  # Without a persisted file there is nothing to point the model at, so a
  # cut would destroy output for good — and the harness had already
  # accepted this much inline. The cap may only raise here, never lower.
  my $full = join '', map {
    sprintf "-rw-r--r--  1 getty getty %6d Apr 24 02:32 file-%04d.txt\n", 1000 + $_, $_
  } 1 .. 500;
  local $ENV{MCP_RUN_COMPRESS_MAX_BYTES} = 100;

  my ($stdout, $stderr, $rc) = run_hook($bin,
    post_payload('ls -la', { stdout => $full }));

  my $updated = decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput};
  ok $updated, 'output was compressed, so the cap had something to bite on'
    or return;

  cmp_ok length($updated->{stdout}), '>', 100,
    'the absurdly low cap did not apply';
  unlike $updated->{stdout}, qr/omitted here/,
    'no cut without a raw file to fall back on';
  like $updated->{stdout}, qr/\Q... 450 more lines ...\E/,
    'only the filter shortened it, and it says so itself';
};

subtest 'post: the cap is configurable' => sub {
  my $tmp  = tempdir(CLEANUP => 1);
  push @keep_alive, $tmp;
  my $file = $tmp->child('big.txt');
  my $full = join '', map { sprintf "line %05d %s\n", $_, 'y' x 60 } 1 .. 2000;
  $file->spew_utf8($full);

  local $ENV{MCP_RUN_COMPRESS_MAX_BYTES} = 4000;
  my ($stdout, $stderr, $rc) = run_hook($bin, post_payload('some-unfiltered-command', {
    stdout              => substr($full, 0, 30000),
    persistedOutputPath => "$file",
    persistedOutputSize => length($full),
  }));

  my $out = decode_json($stdout)->{hookSpecificOutput}{updatedToolOutput}{stdout};
  cmp_ok length($out), '<=', 4000, 'MCP_RUN_COMPRESS_MAX_BYTES is honoured';
  like $out, qr/omitted/, 'still marked';
};

# -------------------------------------------------------------------------
# Fail-open on a broken install (karr #19)
#
# A PreToolUse hook exiting non-zero tells Claude Code to BLOCK the tool
# call, so a half-installed dependency must cost compression, never the
# user's shell. These run the script as a subprocess with a poisoned @INC.
# -------------------------------------------------------------------------
subtest 'pre: fail-open when the compressor cannot be loaded' => sub {
  my $shim = broken_inc('MCP::Run::Compress', 'MCP::Run::Bash');
  my ($stdout, $stderr, $rc) = run_broken($shim, ['--hook'], pre_payload('git commit -m x'));

  is $rc, 0, 'exit 0 — a non-zero PreToolUse hook would block every Bash call';

  my $resp = eval { decode_json($stdout) };
  ok $resp, 'still emits a well-formed hook response' or diag "stdout was: $stdout";
  $resp ||= {};
  is $resp->{hookSpecificOutput}{hookEventName}, 'PreToolUse', 'hookEventName present';
  ok !exists $resp->{hookSpecificOutput}{updatedInput}, 'command passed through unchanged';

  like $stderr, qr/compression unavailable/, 'says why on stderr';
  unlike $stderr, qr/\@INC entries checked/, 'stderr stays terse: no @INC dump';
  is scalar( () = $stderr =~ /\n/g ), 1, 'exactly one line of stderr per command';
};

subtest 'post: fail-open answers with the PostToolUse event name' => sub {
  my $shim = broken_inc('MCP::Run::Compress');
  my ($stdout, $stderr, $rc) = run_broken($shim, ['--hook'],
    post_payload('ls -la', { stdout => "drwxr-xr-x 2 getty getty 4096 x .build\n" }));

  is $rc, 0, 'exit 0';
  my $resp = decode_json($stdout);
  is $resp->{hookSpecificOutput}{hookEventName}, 'PostToolUse',
    'a pass-through carrying the wrong event name would be dropped';
  ok !exists $resp->{hookSpecificOutput}{updatedToolOutput}, 'output left alone';
};

subtest 'hook: fail-open when JSON::MaybeXS itself is missing' => sub {
  my $shim = broken_inc('JSON::MaybeXS');

  my ($stdout, $stderr, $rc) = run_broken($shim, ['--hook'], pre_payload('ls -la'));
  is $rc, 0, 'exit 0 even without the JSON module';
  is $stdout, '{"hookSpecificOutput":{"hookEventName":"PreToolUse"}}',
    'pass-through response is a literal, so emitting it needs no JSON module';

  ($stdout, $stderr, $rc) = run_broken($shim, ['--hook'],
    post_payload('ls -la', { stdout => "x\n" }));
  is $stdout, '{"hookSpecificOutput":{"hookEventName":"PostToolUse"}}',
    'the right literal is picked without parsing the payload';
};

subtest 'hook: an option this version no longer knows must not block Bash' => sub {
  # A settings.json left over from the rewrite era. GetOptions failing on
  # it would exit non-zero, and for PreToolUse that means "block the call".
  my ($stdout, $stderr, $rc) = run([$^X, "-I$lib_path", $bin, '--hook', '--b64', 'bHM='],
    pre_payload('ls -la'));

  is $rc, 0, 'exit 0 despite the unknown flag';
  my $resp = eval { decode_json($stdout) };
  ok $resp, 'well-formed response' or diag "stdout was: $stdout";
  is $resp->{hookSpecificOutput}{hookEventName}, 'PreToolUse', 'and it is a hook response';
};

# -------------------------------------------------------------------------
# --install-claude
# -------------------------------------------------------------------------
subtest 'install: registers the hook for both events' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  push @keep_alive, $tmp;
  local $ENV{HOME} = "$tmp";
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = 'native';

  my ($stdout, $stderr, $rc) = run_install($bin);
  is $rc, 0, 'install exit 0';

  my $settings = $tmp->child('.claude', 'settings.json');
  ok $settings->exists, "settings.json written at $settings";
  my $cfg = decode_json($settings->slurp_utf8);

  for my $event (qw( PreToolUse PostToolUse )) {
    my @cmds = hook_commands($cfg, $event);
    is scalar @cmds, 1, "$event: exactly one Bash hook";
    is $cmds[0], 'mcp-run-compress --hook', "$event: hook command";
  }

  my $skill = $tmp->child('.claude', 'skills',
    'bash-output-is-compressed-prefix-no-compress-to-bypass', 'SKILL.md');
  ok $skill->exists, 'skill file written';
  like $skill->slurp_utf8, qr/no-compress /, 'skill documents the bypass';
  like $skill->slurp_utf8, qr/exit non-zero/,
    'skill names the failed-command limit instead of hiding it';
};

subtest 'install: idempotent' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  push @keep_alive, $tmp;
  local $ENV{HOME} = "$tmp";
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = 'native';

  run_install($bin);
  my $settings = $tmp->child('.claude', 'settings.json');
  my $before   = $settings->slurp_utf8;

  my ($stdout, $stderr, $rc) = run_install($bin);
  is $rc, 0, 'second run exit 0';
  is $settings->slurp_utf8, $before,
    'settings.json byte-identical — a no-op run does not rewrite the user file';

  my $cfg = decode_json($before);
  is scalar hook_commands($cfg, 'PreToolUse'),  1, 'still one PreToolUse hook';
  is scalar hook_commands($cfg, 'PostToolUse'), 1, 'still one PostToolUse hook';
  like $stdout, qr/PreToolUse hook already installed/,  'reports PreToolUse as present';
  like $stdout, qr/PostToolUse hook already installed/, 'reports PostToolUse as present';
};

subtest 'install: migrates a 0.106 installation to the PostToolUse hook' => sub {
  # The practical case: someone who installed before the move has a
  # PreToolUse hook and nothing else. Without the PostToolUse hook nothing
  # is compressed at all any more.
  my $tmp = tempdir(CLEANUP => 1);
  push @keep_alive, $tmp;
  local $ENV{HOME} = "$tmp";
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = 'native';

  my $settings = $tmp->child('.claude', 'settings.json');
  $settings->parent->mkpath;
  $settings->spew_utf8(encode_json({
    hooks => {
      PreToolUse => [ {
        matcher => 'Bash',
        hooks   => [ { type => 'command', command => 'mcp-run-compress --hook' } ],
      } ],
    },
  }));

  my ($stdout, $stderr, $rc) = run_install($bin);
  is $rc, 0, 'migration exit 0';

  my $cfg = decode_json($settings->slurp_utf8);
  is_deeply [ hook_commands($cfg, 'PreToolUse') ], ['mcp-run-compress --hook'],
    'the existing PreToolUse hook is kept, not duplicated';
  is_deeply [ hook_commands($cfg, 'PostToolUse') ], ['mcp-run-compress --hook'],
    'the missing PostToolUse hook is added — that IS the migration';
};

subtest 'install: rewrites a hook entry naming a removed flag' => sub {
  # An entry the current script would reject: GetOptions exits non-zero on
  # it, and a non-zero PreToolUse hook blocks every single Bash call.
  my $tmp = tempdir(CLEANUP => 1);
  push @keep_alive, $tmp;
  local $ENV{HOME} = "$tmp";
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = 'native';

  my $settings = $tmp->child('.claude', 'settings.json');
  $settings->parent->mkpath;
  $settings->spew_utf8(encode_json({
    hooks => {
      PreToolUse => [ {
        matcher => 'Bash',
        hooks   => [ { type => 'command', command => 'mcp-run-compress --filter-files --hook' } ],
      } ],
    },
  }));

  my ($stdout, $stderr, $rc) = run_install($bin);
  my $cfg = decode_json($settings->slurp_utf8);

  is_deeply [ hook_commands($cfg, 'PreToolUse') ], ['mcp-run-compress --hook'],
    'stale flag replaced by the current entry point';
  like $stdout, qr/Migrated stale hook command/, 'and it says so';
};

subtest 'install: rewrites a stale docker image ref' => sub {
  # A pinned older image still does the old PreToolUse rewrite, which
  # compresses inside the command — next to the new PostToolUse hook that
  # would be two compressions on one output.
  my $tmp = tempdir(CLEANUP => 1);
  push @keep_alive, $tmp;
  local $ENV{HOME} = "$tmp";
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = 'docker';
  local $ENV{MCP_RUN_COMPRESS_IMAGE} = 'raudssus/mcp-run-compress:0.107';

  my $settings = $tmp->child('.claude', 'settings.json');
  $settings->parent->mkpath;
  $settings->spew_utf8(encode_json({
    hooks => {
      PreToolUse => [ {
        matcher => 'Bash',
        hooks   => [ { type => 'command',
          command => 'docker run --rm -i raudssus/mcp-run-compress:0.106 --hook' } ],
      } ],
    },
  }));

  my ($stdout, $stderr, $rc) = run_install($bin);
  my $cfg = decode_json($settings->slurp_utf8);
  my ($cmd) = hook_commands($cfg, 'PreToolUse');

  like $cmd, qr/\Qmcp-run-compress:0.107\E/, 'image ref updated to the current one';
  unlike $cmd, qr/\Q0.106\E/, 'the stale pin is gone';
};

subtest 'install: docker mode writes a networkless docker hook' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  push @keep_alive, $tmp;
  local $ENV{HOME} = "$tmp";
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = 'docker';

  run_install($bin);
  my $cfg = decode_json($tmp->child('.claude', 'settings.json')->slurp_utf8);

  for my $event (qw( PreToolUse PostToolUse )) {
    my ($cmd) = hook_commands($cfg, $event);
    like $cmd, qr/\Adocker run .*--hook\z/, "$event: docker run hook command";
    like $cmd, qr/--network none/,
      "$event: no network — the hook reads stdin and writes stdout (karr #14)";
  }
};

subtest 'install: restores a deleted skill even when the hooks are present' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  push @keep_alive, $tmp;
  local $ENV{HOME} = "$tmp";
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = 'native';

  run_install($bin);
  my $skill = $tmp->child('.claude', 'skills',
    'bash-output-is-compressed-prefix-no-compress-to-bypass', 'SKILL.md');
  ok $skill->exists, 'skill present after first install';
  $skill->remove;

  my ($stdout, $stderr, $rc) = run_install($bin);
  is $rc, 0, 'second install exit 0';
  ok $skill->exists, 'deleted skill reinstalled although the hooks were already there';
  like $stdout, qr/\Q$skill\E/, 'output names the skill it (re)installed';
};

subtest 'install: leaves unrelated hooks alone' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  push @keep_alive, $tmp;
  local $ENV{HOME} = "$tmp";
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = 'native';

  my $settings = $tmp->child('.claude', 'settings.json');
  $settings->parent->mkpath;
  $settings->spew_utf8(encode_json({
    hooks => {
      PostToolUse => [ {
        matcher => 'Bash',
        hooks   => [ { type => 'command', command => 'some-other-hook --do-things' } ],
      } ],
    },
    someOtherSetting => 'kept',
  }));

  run_install($bin);
  my $cfg = decode_json($settings->slurp_utf8);

  is $cfg->{someOtherSetting}, 'kept', 'unrelated settings survive';
  my @all = map { $_->{command} }
            map { @{ $_->{hooks} // [] } }
            @{ $cfg->{hooks}{PostToolUse} };
  ok scalar( grep { $_ eq 'some-other-hook --do-things' } @all ), 'foreign hook kept';
  ok scalar( grep { $_ eq 'mcp-run-compress --hook' } @all ),     'ours added';
};

done_testing;

# -------------------------------------------------------------------------
# helpers
# -------------------------------------------------------------------------

sub run {
  my ($cmd, $stdin_data) = @_;
  my ($in_fh, $out_fh, $err_fh);
  $err_fh = gensym;
  my $pid = open3($in_fh, $out_fh, $err_fh, @$cmd);
  print {$in_fh} $stdin_data if defined $stdin_data;
  close $in_fh;

  # Slurp both pipes before waitpid — otherwise the child can block on
  # a full pipe buffer when output exceeds ~64KiB.
  my $stdout = do { local $/; <$out_fh> // '' };
  close $out_fh;
  my $stderr = (defined $err_fh && fileno($err_fh)) ? (do { local $/; <$err_fh> // '' }) : '';
  close $err_fh if defined $err_fh && fileno($err_fh);

  waitpid($pid, 0);
  return ($stdout, $stderr, $? >> 8);
}

sub run_hook {
  my ($bin, $stdin_data) = @_;
  return run([$^X, "-I$lib_path", $bin, '--hook'], $stdin_data);
}

sub run_install {
  my ($bin) = @_;
  return run([$^X, "-I$lib_path", $bin, '--install-claude']);
}

sub pre_payload {
  my ($cmd) = @_;
  return encode_json({
    hook_event_name => 'PreToolUse',
    tool_name       => 'Bash',
    tool_input      => { command => $cmd },
  });
}

sub post_payload {
  my ($cmd, $response) = @_;
  return encode_json({
    hook_event_name => 'PostToolUse',
    tool_name       => 'Bash',
    tool_input      => { command => $cmd },
    tool_response   => $response,
  });
}

# All Bash-matched hook commands registered for one event.
sub hook_commands {
  my ($cfg, $event) = @_;
  return map  { $_->{command} // '' }
         grep { ref $_ eq 'HASH' }
         map  { @{ $_->{hooks} // [] } }
         grep { ref $_ eq 'HASH' && ($_->{matcher} // '') eq 'Bash' }
         @{ $cfg->{hooks}{$event} // [] };
}

# A directory that shadows real modules with copies that blow up on load —
# what a half-finished cpanm upgrade or a Perl version switch leaves behind.
# It goes first in @INC and lib/ is left out, so the failure happens whether
# or not MCP::Run is also installed system-wide.
sub broken_inc {
  my (@modules) = @_;
  my $dir = tempdir(CLEANUP => 1);
  push @keep_alive, $dir;
  for my $module (@modules) {
    ( my $rel = $module ) =~ s{::}{/}g;
    my $file = $dir->child("$rel.pm");
    $file->parent->mkpath;
    $file->spew_utf8(<<'STUB');
die "Can't locate Text/Trim.pm in \@INC (you may need to install the Text::Trim module) (\@INC entries checked: /one /two /three /four /five /six /seven) at stub line 1.\n";
1;
STUB
  }
  return $dir;
}

# Note the missing -I$lib_path: the point is a @INC that cannot serve the
# script's own dependencies.
sub run_broken {
  my ($shim, $args, $stdin) = @_;
  local $ENV{PERL5LIB} = '';
  return run([$^X, "-I$shim", $bin, @$args], $stdin);
}

sub encode_json {
  my ($data) = @_;
  return JSON::MaybeXS->new(utf8 => 1, canonical => 1)->encode($data);
}

sub decode_json {
  my ($s) = @_;
  return JSON::MaybeXS->new(utf8 => 1, canonical => 1)->decode($s);
}
