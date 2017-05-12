#!/usr/bin/perl -w
use strict;
use Test::More;

plan tests => 31;

use IO::CaptureOutput qw/capture_exec capture_exec_combined qxx qxy/;

my ($out, $err, $suc, $ec);
my @perl_e = ($^X, '-e'); # perl -e

sub _reset { $_ = '' for ($out, $err); undef $suc; undef $ec; 1};

# low-level debugging
#print capture_exec($^X, '-e', 'print join "|", @ARGV'), "\n";
#print join '|', IO::CaptureOutput::_shell_quote($^X, '-e', 'print join "|", @ARGV'), "\n";

# simple test
($out, $err, $suc, $ec) = capture_exec(@perl_e, q[print 'Hello World!'; print STDERR "PID=$$"]);
is($out, 'Hello World!', 'capture_exec() caught stdout from external command');
like($err, '/PID=\d+/', 'capture_exec() caught stderr from external command');
ok($suc, 'capture_exec() returned success');
is($ec >> 8, 0, 'capture_exec() exit value');

# with alias
_reset;
($out, $err, $suc, $ec) = qxx(@perl_e, q[print 'Hello World!'; print STDERR "PID=$$"]);
is($out, 'Hello World!', 'capture_exec() caught stdout from external command');
like($err, '/PID=\d+/', 'capture_exec() caught stderr from external command');
ok($suc, 'capture_exec() returned success');
is($ec >> 8, 0, 'capture_exec() exit value');

# check exit code of system()
_reset;
($out, $err, $suc, $ec) = capture_exec(@perl_e, 'print "ok"');
ok($out eq 'ok' && $? == 0, '$? set to 0 after successful execution');
ok($suc, 'returned success flag correct on exit 0');
is($ec >> 8, 0, 'returned exit value correct on exit 0');

_reset;
($out, $err, $suc, $ec) = capture_exec(@perl_e, 'exit 5');
is($? >> 8, 5, '$? contains child error after failed execution');
ok(!$suc, 'returned success flag correct on exit N');
is($ec >> 8, 5, 'returned exit value correct on exit N');

# check that output is returned if called in scalar context
_reset;
$out = capture_exec(@perl_e, 'print "stdout"; print STDERR "stderr"');
is($out, 'stdout', 'capture_exec() returns stdout in scalar context');

# merge STDOUT and STDERR
_reset;
($out, $suc, $ec) = capture_exec_combined(@perl_e, q[select STDERR; $|++; select STDOUT; $|++; print "Hello World!\n"; print STDERR "PID=$$\n"]);
like($out, '/Hello World!/', 'capture_exec_combined() caught stdout from external command');
like($out, '/PID=\d+/', 'capture_exec_combined() caught stderr from external command');
ok($suc, 'returned success flag correct on exit 0');
is($ec >> 8, 0, 'returned exit value correct on exit 0');

# with alias
_reset;
($out, $suc, $ec) = qxy(@perl_e, q[select STDERR; $|++; select STDOUT; $|++; print "Hello World!\n"; print STDERR "PID=$$\n"]);
like($out, '/Hello World!/', 'capture_exec_combined() caught stdout from external command');
like($out, '/PID=\d+/', 'capture_exec_combined() caught stderr from external command');
ok($suc, 'returned success flag correct on exit 0');
is($ec >> 8, 0, 'returned exit value correct on exit 0');

# check exit code of system()
_reset;
($out, $suc, $ec) = qxy(@perl_e, 'print "ok"');
ok($out eq 'ok' && $? == 0, '$? set to 0 after successful execution');
ok($suc, 'returned success flag correct on exit 0');
is($ec >> 8, 0, 'returned exit value correct on exit 0');

_reset;
($out, $suc, $ec) = qxy(@perl_e, 'exit 5');
is($? >> 8, 5, '$? contains child error after failed execution');
ok(!$suc, 'returned success flag correct on exit N');
is($ec >> 8, 5, 'returned exit value correct on exit N');

# merge STDOUT and STDERR
_reset;
$out = capture_exec_combined(@perl_e, q[select STDERR; $|++; select STDOUT; $|++; print "Hello World!\n"; print STDERR "PID=$$\n"]);
like($out, '/Hello World!/', 'capture_exec_combined() caught stdout from external command');
like($out, '/PID=\d+/', 'capture_exec_combined() caught stderr from external command');
