use strict;
use warnings;
use Test::More;
use lib 'lib';
use IPC::Open3 qw( open3 );
use Symbol        qw( gensym );
use JSON::MaybeXS ();
use MIME::Base64  qw( encode_base64 );
use Encode        qw( encode_utf8 );
use Path::Tiny    qw( path tempdir );

# Coverage for the bin/mcp-run-compress modes the karr board calls out
# as untested: --hook, --install-claude (settings patching), Docker
# rewrite path, --filter-files, and end-to-end MCP compression with a
# real command context.

my $bin = path($0)->parent->parent->child('bin', 'mcp-run-compress');
ok(-x $bin, "bin/mcp-run-compress is executable: $bin") or BAIL_OUT("binary missing");
my $lib_path = path($0)->parent->parent->child('lib')->realpath;

# -------------------------------------------------------------------------
# --hook
# -------------------------------------------------------------------------
subtest 'hook: rewrites Bash command to --b64 wrap (native mode)' => sub {
  my $in = encode_json({ tool_input => { command => 'ls -la' } });
  my ($stdout, $stderr, $rc) = run_hook($bin, $in, 'native');
  is $rc, 0, 'hook exit 0';

  my $resp = decode_json($stdout);
  like $resp->{hookSpecificOutput}{updatedInput}{command},
    qr/^mcp-run-compress --b64 /,
    'rewrite is native --b64 form';
};

subtest 'hook: docker mode emits pipe-through-docker rewrite' => sub {
  my $in = encode_json({ tool_input => { command => 'git status' } });
  my ($stdout, $stderr, $rc) = run_hook($bin, $in, 'docker');
  is $rc, 0, 'hook exit 0';

  my $resp = decode_json($stdout);
  my $cmd = $resp->{hookSpecificOutput}{updatedInput}{command};
  like $cmd, qr/^\{\s/,              'docker rewrite starts with a brace group';
  like $cmd, qr/base64 -d/,           'docker rewrite decodes the payload';
  like $cmd, qr/base64 -d/,           'docker rewrite decodes the payload';
  like $cmd, qr/docker run/,          'docker rewrite invokes docker';
  like $cmd, qr/--filter-files/,      'docker rewrite uses --filter-files';
};

subtest 'hook: bypasses background commands' => sub {
  my $in = encode_json({ tool_input => { command => 'sleep 10', run_in_background => 1 } });
  my ($stdout, $stderr, $rc) = run_hook($bin, $in, 'native');
  my $resp = decode_json($stdout);
  ok !exists $resp->{hookSpecificOutput}{updatedInput},
    'background command not rewritten';
};

subtest 'hook: bypasses already-wrapped commands' => sub {
  my $in = encode_json({ tool_input => { command => 'mcp-run-compress --b64 foo' } });
  my ($stdout, $stderr, $rc) = run_hook($bin, $in, 'native');
  my $resp = decode_json($stdout);
  ok !exists $resp->{hookSpecificOutput}{updatedInput},
    'already-wrapped command passed through';
};

subtest 'hook: no-compress prefix strips and bypasses' => sub {
  my $in = encode_json({ tool_input => { command => 'no-compress ls -la' } });
  my ($stdout, $stderr, $rc) = run_hook($bin, $in, 'native');
  my $resp = decode_json($stdout);
  is $resp->{hookSpecificOutput}{updatedInput}{command}, 'ls -la',
    'no-compress prefix stripped';
};

subtest 'hook: malformed input returns safe response' => sub {
  my ($stdout, $stderr, $rc) = run_hook_raw($bin, 'not json at all', 'native');
  my $resp = decode_json($stdout);
  is $resp->{hookSpecificOutput}{hookEventName}, 'PreToolUse',
    'hookEventName set even with malformed input';
  ok !exists $resp->{hookSpecificOutput}{updatedInput},
    'no rewrite on malformed input';
};

# -------------------------------------------------------------------------
# --b64: end-to-end MCP compression with real command context
# -------------------------------------------------------------------------
subtest 'b64: executes real bash command, returns compressed streams' => sub {
  my $cmd = 'echo hello world';
  my ($stdout, $stderr, $rc) = run_b64($bin, $cmd);
  is $rc, 0, 'exit 0';
  like $stdout, qr/hello world/, 'stdout contains echo result';
};

subtest 'b64: failing command returns non-zero exit' => sub {
  my ($stdout, $stderr, $rc) = run_b64($bin, 'false');
  is $rc, 1, 'false exits 1';
};

subtest 'b64: ls -la output runs through ls filter (no permission columns)' => sub {
  my ($stdout, $stderr, $rc) = run_b64($bin, 'ls -la /tmp');
  is $rc, 0, 'ls exit 0';
  if ($stdout =~ /\A[d-]/m) {
    unlike $stdout, qr/drwxr-xr-x/, 'permissions stripped by ls filter';
  } else {
    pass 'no ls long-listing lines present';
  }
};

# -------------------------------------------------------------------------
# --filter-files
# -------------------------------------------------------------------------
subtest 'filter-files: reads captured files and emits compressed streams' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  my $out_path = $tmp->child('out');
  my $err_path = $tmp->child('err');
  $out_path->spew_utf8(
    "drwxr-xr-x  2 getty getty 4096 Apr 24 02:32 .build\n"
  . "-rw-r--r--  1 getty getty   42 Apr 24 02:32 README.md\n"
  );
  $err_path->spew_utf8('');

  my $cmd = 'ls -la';
  my ($stdout, $stderr, $rc) = run_filter_files($bin, $cmd, $out_path, $err_path);

  is $rc, 0, 'filter-files exit 0';
  like $stdout, qr/\.build/,     'compressed stdout keeps entry';
  unlike $stdout, qr/drwxr-xr-x/, 'ls filter stripped permissions';
};

# -------------------------------------------------------------------------
# --install-claude
# -------------------------------------------------------------------------
subtest 'install-claude: registers PreToolUse hook in settings.json' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  local $ENV{HOME} = "$tmp";
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = 'native';

  my ($stdout, $stderr, $rc) = run_install_claude($bin);
  is $rc, 0, 'install exit 0';

  my $settings = $tmp->child('.claude', 'settings.json');
  ok $settings->exists, "settings.json written at $settings";
  my $cfg = decode_json($settings->slurp_utf8);
  ok exists $cfg->{hooks}{PreToolUse}, 'PreToolUse key present';

  my @matched = grep { ref $_ eq 'HASH' && ($_->{matcher} // '') eq 'Bash' }
                @{ $cfg->{hooks}{PreToolUse} };
  ok @matched, 'Bash matcher group present';
  my @hooks_in_group = @matched ? @{ $matched[0]{hooks} // [] } : ();
  my $has_hook_cmd = scalar grep { ($_->{command} // '') =~ /mcp-run-compress --hook/ } @hooks_in_group;
  ok($has_hook_cmd, 'hook command references mcp-run-compress --hook');

  my $skill = $tmp->child('.claude', 'skills',
    'bash-output-is-compressed-prefix-no-compress-to-bypass', 'SKILL.md');
  ok $skill->exists, 'skill file written';
};

subtest 'install-claude: idempotent (second run is a no-op)' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  local $ENV{HOME} = "$tmp";
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = 'native';

  run_install_claude($bin);
  run_install_claude($bin);

  my $cfg = decode_json($tmp->child('.claude', 'settings.json')->slurp_utf8);
  my @groups = grep { ref $_ eq 'HASH' && ($_->{matcher} // '') eq 'Bash' }
               @{ $cfg->{hooks}{PreToolUse} };
  is scalar @groups, 1, 'still exactly one Bash matcher group after second run';
};

subtest 'install-claude: docker mode writes docker hook command' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  local $ENV{HOME} = "$tmp";
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = 'docker';

  run_install_claude($bin);
  my $cfg = decode_json($tmp->child('.claude', 'settings.json')->slurp_utf8);
  my @groups = grep { ref $_ eq 'HASH' && ($_->{matcher} // '') eq 'Bash' }
               @{ $cfg->{hooks}{PreToolUse} };
  ok @groups, 'Bash matcher group present in docker mode';
  my @docker_hooks = @groups ? @{ $groups[0]{hooks} // [] } : ();
  my $has_docker_cmd = scalar grep { ($_->{command} // '') =~ /docker run.*--hook/ } @docker_hooks;
  ok($has_docker_cmd, 'docker mode hook command references docker run --hook');
};

done_testing;

# -------------------------------------------------------------------------
# helpers — IPC::Open3 with separate stdout / stderr
# -------------------------------------------------------------------------

sub run {
  my ($cmd, $stdin_data) = @_;
  my ($in_fh, $out_fh, $err_fh);
  $err_fh = gensym;
  my $pid = open3($in_fh, $out_fh, $err_fh, @$cmd);
  if (defined $stdin_data) {
    print {$in_fh} $stdin_data;
  }
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
  my ($bin, $json_in, $mode) = @_;
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = $mode;
  return run_hook_raw($bin, $json_in, $mode);
}

sub run_hook_raw {
  my ($bin, $stdin_data, $mode) = @_;
  local $ENV{MCP_RUN_COMPRESS_INSTALL_MODE} = $mode;
  return run([$^X, "-I$lib_path", $bin, '--hook'], $stdin_data);
}

sub run_b64 {
  my ($bin, $cmd) = @_;
  my $enc = encode_base64(encode_utf8($cmd), '');
  return run([$^X, "-I$lib_path", $bin, '--b64', $enc]);
}

sub run_filter_files {
  my ($bin, $cmd, $out_path, $err_path) = @_;
  my $enc = encode_base64(encode_utf8($cmd), '');
  return run([$^X, "-I$lib_path", $bin, '--filter-files', '--cmd-b64', $enc,
              "$out_path", "$err_path"]);
}

sub run_install_claude {
  my ($bin) = @_;
  return run([$^X, "-I$lib_path", $bin, '--install-claude']);
}

sub encode_json {
  my ($data) = @_;
  return JSON::MaybeXS->new(utf8 => 1, canonical => 1)->encode($data);
}

sub decode_json {
  my ($s) = @_;
  return JSON::MaybeXS->new(utf8 => 1, canonical => 1)->decode($s);
}
