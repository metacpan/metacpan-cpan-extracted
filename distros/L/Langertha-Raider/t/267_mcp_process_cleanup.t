#!/usr/bin/env perl
# ABSTRACT: no MCP server process outlives bin/raider: one-shot, REPL end, SIGTERM; notes on stderr only (ADR 0029, k164)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use FindBin;
use JSON::MaybeXS ();
use Path::Tiny;
use POSIX qw( WNOHANG );
use Time::HiRes ();
use lib "$FindBin::Bin/lib";
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::Env qw( clear_engine_env );

clear_engine_env();
my $repo   = path($FindBin::Bin)->parent->realpath;
my $bin    = $repo->child('bin', 'raider');
my $script = path($FindBin::Bin)->child('lib', 'mcp-test-server.pl')->realpath->stringify;
my $json   = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );

# A home with one raider-home server (writes its pid) and a Claude Code
# project whose .mcp.json server nobody approved.
sub setup {
  my $home = path(tempdir(CLEANUP => 1))->realpath;
  my $root = path(tempdir(CLEANUP => 1))->realpath;
  my $pidfile = $home->child('server.pid');
  my $pending = $home->child('pending.pid');
  $home->child('.raider')->mkpath;
  $home->child('.raider', 'config.yml')->spew_utf8("mcp:\n  t:\n    command: \"$^X\"\n"
    ."    args: [ \"$script\", \"--pidfile\", \"$pidfile\", \"normal\" ]\n");
  $root->child('CLAUDE.md')->spew_utf8("# p\n");
  $root->child('.mcp.json')->spew_raw($json->encode({ mcpServers => {
    proj => { command => $^X, args => [ $script, '--pidfile', "$pending", 'normal' ] } } }));
  return ( $home, $root, $pidfile, $pending );
}

# Starts bin/raider with @args; stdin from $stdin (a string, or undef for a
# pipe kept open); returns ( pid, write handle or undef, stdout file, stderr file ).
sub spawn {
  my ( $home, $root, $stdin, @args ) = @_;
  my $out = $home->child('out');
  my $err = $home->child('err');
  my $in_file = $home->child('in');
  $in_file->spew_utf8($stdin // '');
  my ( $r, $w );
  pipe $r, $w or die $! unless defined $stdin;
  my $pid = fork // die 'fork: '.$!;
  unless ($pid) {
    if (defined $stdin) { open STDIN, '<', "$in_file" or die $! }
    else                { close $w; open STDIN, '<&', $r or die $! }
    open STDOUT, '>', "$out" or die $!;
    open STDERR, '>', "$err" or die $!;
    $ENV{HOME} = "$home";
    delete $ENV{CLAUDE_CONFIG_DIR};
    exec $^X, '-I'.$repo->child('lib'), "$bin", '-r', "$root", '-e', 'mock', '--no-trace', '--no-session', @args;
    die 'exec: '.$!;
  }
  close $r if $r;
  return ( $pid, $w, $out, $err );
}

sub reap {
  my ( $pid ) = @_;
  my $deadline = Time::HiRes::time() + 60;
  while (Time::HiRes::time() < $deadline) {
    return $? if waitpid($pid, WNOHANG) == $pid;
    Time::HiRes::sleep(0.05);
  }
  kill KILL => $pid;
  waitpid $pid, 0;
  return -1;
}

sub wait_for_file {
  my ( $file ) = @_;
  my $deadline = Time::HiRes::time() + 30;
  Time::HiRes::sleep(0.05) until -s $file || Time::HiRes::time() > $deadline;
  return -s $file;
}

# A process is gone once kill 0 fails (it is not our child, so no zombie).
sub gone {
  my ( $pid ) = @_;
  my $deadline = Time::HiRes::time() + 5;
  while (Time::HiRes::time() < $deadline) {
    return 1 unless kill 0, $pid;
    Time::HiRes::sleep(0.05);
  }
  return 0;
}

subtest 'one-shot --json: server stopped at the end, pending note on stderr' => sub {
  my ( $home, $root, $pidfile, $pending ) = setup();
  my ( $pid, undef, $out, $err ) = spawn($home, $root, '', '--json', 'hello');
  # -e mock has no rule for the prompt, so the run itself fails (exit 1);
  # what counts here is that the servers started first and are gone after.
  is(reap($pid), 256, 'raider ended (the mock run fails)') or diag $err->slurp_utf8.$out->slurp_utf8;
  my $doc = eval { $json->decode($out->slurp_raw) };
  ok($doc && $doc->{status}, 'stdout is one JSON document') or diag $out->slurp_raw;
  like($err->slurp_utf8, qr/^mcp: server proj \(\.mcp\.json\) is not approved and stays off; /m, 'the note is on stderr');
  ok(-s $pidfile, 'the configured server was started');
  my $server = $pidfile->slurp;
  ok(gone($server), 'and is gone after raider');
  ok(!-e $pending, 'the pending server never started');
};

subtest 'REPL: /mcp, then the end of input stops the server' => sub {
  my ( $home, $root, $pidfile ) = setup();
  my ( $pid, undef, $out, $err ) = spawn($home, $root, "hello\n/mcp\n", '-i');
  is(reap($pid), 0, 'exit 0') or diag $err->slurp_utf8;
  my $text = $out->slurp_utf8;
  like($text, qr/mcp: server proj \(\.mcp\.json\) is not approved/, 'without a terminal the REPL cannot ask: the note');
  like($text, qr/^  t connected  raider-home, stdio/m, '/mcp shows the running server');
  like($text, qr/^  proj pending approval/m, 'and the pending one');
  ok(gone($pidfile->slurp), 'the server is gone after the REPL');
};

subtest 'one-shot /mcp: connects, reports, stops; /mcp reconnect is REPL-only' => sub {
  my ( $home, $root, $pidfile, $pending ) = setup();
  my ( $pid, undef, $out, $err ) = spawn($home, $root, '', '-p', '/mcp');
  is(reap($pid), 0, 'exit 0') or diag $err->slurp_utf8;
  my $text = $out->slurp_utf8;
  like($text, qr/^  t connected  raider-home, stdio, ~\/\.raider\/config\.yml\n    tools: mcp__t__boom/m, 'connected, with its tools');
  like($text, qr/^  proj pending approval  project, stdio, \.mcp\.json$/m, 'the pending one, not started');
  ok(!-e $pending, 'the pending server never started');
  ok(-s $pidfile && gone($pidfile->slurp), 'the started server is gone after raider');

  ( $pid, undef, $out, $err ) = spawn($home, $root, '', '-p', '/mcp reconnect t');
  is(reap($pid), 2 << 8, 'reconnect: exit 2');
  like($err->slurp_utf8, qr{^/mcp reconnect: not in a one-shot run, only in the REPL$}m, 'says why');
};

subtest 'REPL killed by SIGTERM: the server goes too' => sub {
  my ( $home, $root, $pidfile ) = setup();
  my ( $pid, $w, $out, $err ) = spawn($home, $root, undef, '-i');
  $w->autoflush(1);
  print {$w} "hello\n";
  ok(wait_for_file($pidfile), 'the server started with the first raid');
  my $server = $pidfile->slurp;
  Time::HiRes::sleep(0.3);
  kill TERM => $pid;
  reap($pid);
  close $w;
  ok(gone($server), 'the server is gone after SIGTERM');
};

done_testing;
