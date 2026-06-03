#!/usr/bin/env perl
# Author test: re-run xt/89_leak.t under valgrind. Fails on any
# definitely-lost block.
#
# Skipped unless EV_GEARMAN_VALGRIND=1 (so it does not run during
# normal `make test`). Requires valgrind in PATH and a live
# gearmand reachable via TEST_GEARMAN_HOST / TEST_GEARMAN_PORT.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

plan skip_all => 'set EV_GEARMAN_VALGRIND=1 to enable' unless $ENV{EV_GEARMAN_VALGRIND};
plan skip_all => 'valgrind not in PATH' unless `which valgrind` =~ /\S/;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;
require IO::Socket::INET;
my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port,
    Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

plan tests => 2;

my (undef, $logfile) = tempfile('ev_gm_vg_XXXXXX', SUFFIX => '.log',
                                TMPDIR => 1, UNLINK => 0);
my (undef, $childlog) = tempfile('ev_gm_vg_child_XXXXXX', SUFFIX => '.log',
                                  TMPDIR => 1, UNLINK => 0);

my @cmd = (
    qw(valgrind
       --error-exitcode=99
       --leak-check=full
       --show-leak-kinds=definite
       --errors-for-leak-kinds=definite
       --num-callers=30
       --child-silent-after-fork=yes),
    "--log-file=$logfile",
    $^X, '-Iblib/lib', '-Iblib/arch', 'xt/89_leak.t',
);

diag "running: @cmd";
my $cmd = join(' ', map { /\s/ ? "'$_'" : $_ } @cmd) . " >$childlog 2>&1";
my $rc = system $cmd;
my $exit = $rc >> 8;

ok($exit != 99, 'no definite leaks reported by valgrind');
ok($exit == 0,  'leak suite exits cleanly under valgrind');

if ($exit) {
    diag "valgrind log: $logfile";
    diag "child output: $childlog";
    if (open my $fh, '<', $logfile) {
        my @tail;
        while (<$fh>) { push @tail, $_; shift @tail while @tail > 80 }
        diag $_ for @tail;
    }
} else {
    unlink $logfile, $childlog;
}
