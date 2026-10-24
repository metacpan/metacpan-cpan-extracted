use strict;
use warnings;
use Test::More;
use IPC::Open3 qw( open3 );
use Symbol        qw( gensym );
use JSON::MaybeXS ();
use Path::Tiny    qw( path tempdir );

# MCP::Constants is upstream, not ours — importing it does not weaken the
# subprocess-only discipline below, which is about never loading MCP::Run*.
# The version pin mirrors t/20-integration.t: without it a stale MCP in @INC
# dies with "not exported by MCP::Constants" instead of naming the real cause.
use MCP 0.15;
use MCP::Constants qw( META_SERVER_INFO );

# Coverage for bin/mcp-run-bash driven the way a real MCP client drives it:
# a subprocess speaking JSON-RPC over stdio.
#
# This file deliberately does NOT load MCP::Run::Bash or MCP::Run::Compress.
# The bug this guards against (MCP::Run calling MCP::Run::Compress->new
# without anything ever loading that module) is invisible to any test that
# instantiates the modules itself, because loading Compress from the test
# process papers over the missing load in lib/. Only a fresh interpreter
# running the shipped script can see it.

my $bin = path($0)->parent->parent->child('bin', 'mcp-run-bash');
ok(-e $bin, "bin/mcp-run-bash exists: $bin") or BAIL_OUT("binary missing");
my $lib_path = path($0)->parent->parent->child('lib')->realpath;

# Compression is ON by default in bin/mcp-run-bash (it sets compress => 1
# unconditionally), so the plain default config is exactly the broken case.
subtest 'default config: tools/call succeeds with compression on' => sub {
  my $responses = run_mcp({}, tool_call('echo hallo'));

  my $call = $responses->{3};
  ok $call, 'got a response for the tools/call' or return;
  ok !$call->{error}, 'no JSON-RPC error'
    or diag "error: $call->{error}{code} $call->{error}{message}";

  my $text = $call->{result}{content}[0]{text} // '';
  like $text, qr/Exit code: 0/, 'exit code in output';
  like $text, qr/hallo/,        'command output in result';
};

# Guards the fix from being "satisfied" by disabling compression: with the
# default config the ls filter must visibly rewrite the listing, and with
# MCP_RUN_COMPRESS=0 the very same call must return it raw.
subtest 'default config: compression filters actually run' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  $tmp->child('README.md')->spew_utf8('example');

  my $on = run_mcp({}, tool_call("ls -la $tmp"));
  my $on_text = $on->{3}{result}{content}[0]{text} // '';

  like $on_text, qr/^- README\.md$/m, 'ls filter collapsed the entry to "- README.md"';
  unlike $on_text, qr/drwxr-xr-x/,    'permission columns stripped';
  unlike $on_text, qr/^total \d+/m,   'total line stripped';

  my $off = run_mcp({ MCP_RUN_COMPRESS => 0 }, tool_call("ls -la $tmp"));
  my $off_text = $off->{3}{result}{content}[0]{text} // '';

  like $off_text, qr/^-rw\S*\s.*README\.md$/m, 'uncompressed run keeps the raw long listing';
};

# The shipped script passes neither name nor version to run_stdio, so before
# MCP::Run::Bash carried its own defaults every client saw MCP::Server's
# 'PerlServer' / '1.0.0'. Asserted here rather than only on the class, so it
# covers what a real client is actually told.
subtest 'default config: serverInfo identifies the distribution' => sub {
  # Read from the source rather than loading the module, keeping this file's
  # subprocess-only discipline intact.
  my $src = path($lib_path)->child('MCP', 'Run', 'Bash.pm')->slurp_utf8;
  my ($dist_version) = $src =~ /^our \$VERSION = '([^']+)'/m;
  ok $dist_version, "found \$VERSION in Bash.pm: " . ($dist_version // '?') or return;

  my $responses = run_mcp({}, tool_call('true'));
  my $init = $responses->{1};
  ok $init, 'got a response for initialize' or return;

  # 0.15 puts serverInfo in result._meta; the legacy handshake also mirrors it
  # into the result body, which is where a legacy client reads it. The _meta
  # key comes from the constant, not spelled out: if MCP renames it, the
  # import fails loudly instead of the // silently yielding undef and the
  # failure reading as "server name is wrong".
  my $info = $init->{result}{serverInfo} // $init->{result}{_meta}{+META_SERVER_INFO};

  is $info->{name},    'mcp-run-bash', 'server name is the distribution, not PerlServer';
  is $info->{version}, $dist_version,  'server version is the distribution version, not 1.0.0';
};

# karr #21: MCP_RUN_TIMEOUT used to be numified with `+ 0`, which takes any
# string: '30s' became 30, 'abc' became 0, '1e400' became Inf, each with a
# Perl warning on the stderr of a stdio server and no word to the user that
# the configured value had been dropped. The env var is configuration a human
# wrote into .mcp.json, not a per-call argument from the model: a typo there
# must not be guessed at, so the server refuses to start.
#
# 'abc' and '30s' are the warning cases; '0' and '-5' are values MCP::Run::Bash
# would silently replace with its default; '9999999999' is digits-only and
# looks fine here but is past the alarm() ceiling below, so it would be
# dropped one layer down without a trace. All of them are configuration the
# user got wrong, and all of them must say so rather than run as something
# else.
subtest 'an unusable MCP_RUN_TIMEOUT refuses the start instead of guessing' => sub {
  for my $bad ('abc', '30s', '5m', '0', '-5', '1e400', '  ', '9999999999', '2.5') {
    my ($responses, $stderr, $rc) = run_mcp({ MCP_RUN_TIMEOUT => $bad }, tool_call('echo hallo'));

    isnt $rc, 0, "MCP_RUN_TIMEOUT='$bad': server exits non-zero";
    is scalar keys %$responses, 0,
      "MCP_RUN_TIMEOUT='$bad': no JSON-RPC response, the server never came up";

    like $stderr, qr/MCP_RUN_TIMEOUT/,
      "MCP_RUN_TIMEOUT='$bad': the message names the variable";
    like $stderr, qr/\Q$bad\E/,
      "MCP_RUN_TIMEOUT='$bad': the message quotes the rejected value";

    # The other half of the finding: no Perl warning may reach the stderr of a
    # stdio server. Every warn() and every uncaught die carries an "at FILE
    # line N" tail, which our own message deliberately does not, so this goes
    # red both for the old "isn't numeric" noise and for any later mishap.
    unlike $stderr, qr/isn't numeric/,
      "MCP_RUN_TIMEOUT='$bad': no numeric-conversion warning";
    unlike $stderr, qr/ at \S+ line \d+/,
      "MCP_RUN_TIMEOUT='$bad': nothing on stderr but the diagnosis";
  }
};

# The flip side: a value that passes validation has to arrive as the server
# default, not merely be accepted. A one second timeout against `sleep 5` is
# the cheapest way to observe the number the runner actually armed alarm()
# with -- MCP::Run::Bash reports it in the timeout message.
subtest 'a valid MCP_RUN_TIMEOUT reaches the runner' => sub {
  my ($responses, $stderr, $rc) = run_mcp({ MCP_RUN_TIMEOUT => '1' }, tool_call('sleep 5'));

  my $text = $responses->{3}{result}{content}[0]{text} // '';
  like $text, qr/Exit code: 124/,             'command was timed out';
  like $text, qr/timed out after 1s/,         'the timeout that ran is the configured one';
  is $stderr, '', 'clean stderr' or diag "stderr: $stderr";
  is $rc, 0, 'server exited cleanly';
};

done_testing;

# A classic 'initialize' handshake followed by the tools/call. This is what
# Claude Desktop and Claude Code send, and driving it through a real pipe
# exercises MCP::Server::Transport::Stdio and the MCP::Server::Legacy
# handshake path — the one that skips _check_meta — instead of hand-building
# an MCP::Server::Context.
#
# It does NOT exercise protocol-revision negotiation: legacy_request() echoes
# a known revision back and silently substitutes its newest ('2025-11-25')
# for anything else, so no version string is ever rejected and this test runs
# identically with any value here. Real revision checking is asserted in the
# 'protocol contract' subtest of t/20-integration.t, over the modern path.
#
# Keep this on the classic handshake (see karr #7): its value is that it goes
# red the day MCP drops the legacy path, which is the early warning that
# Claude Desktop and Claude Code can no longer talk to mcp-run-bash.
sub tool_call {
  my ($command) = @_;
  return (
    { jsonrpc => '2.0', id => 1, method => 'initialize',
      params => { protocolVersion => '2025-11-25', capabilities => {},
                  clientInfo => { name => 'test', version => '1.0' } } },
    { jsonrpc => '2.0', id => 3, method => 'tools/call',
      params => { name => 'run', arguments => { command => $command } } },
  );
}

# Returns the decoded responses keyed by JSON-RPC id.
sub run_mcp {
  my ($env, @requests) = @_;
  local @ENV{ keys %$env } = values %$env;

  my $stdin_data = join '', map { encode_json($_) . "\n" } @requests;
  my ($stdout, $stderr, $rc) = run([$^X, "-I$lib_path", "$bin"], $stdin_data);

  my %by_id;
  for my $line (split /\n/, $stdout) {
    next unless $line =~ /\A\s*\{/;
    my $msg = eval { decode_json($line) } or next;
    $by_id{ $msg->{id} } = $msg if defined $msg->{id};
  }
  return wantarray ? (\%by_id, $stderr, $rc) : \%by_id;
}

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

sub encode_json { JSON::MaybeXS->new(utf8 => 1, canonical => 1)->encode($_[0]) }
sub decode_json { JSON::MaybeXS->new(utf8 => 1, canonical => 1)->decode($_[0]) }
