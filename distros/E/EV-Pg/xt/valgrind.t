#!/usr/bin/env perl
# Author test: re-run t/05_leak.t under valgrind and fail on definite leaks.
#
# Skipped unless EV_PG_VALGRIND=1 (so it doesn't run during normal `make
# test`).  Requires valgrind in PATH and a live PostgreSQL via
# TEST_PG_CONNINFO.
#
# This is the only canonical leak harness — t/05_leak.t exercises the
# leak-prone paths (notify, COPY, pipeline, notice receiver, prepared
# statements, destruction-in-callback) and this script verifies they
# are actually leak-free under valgrind.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

plan skip_all => 'set EV_PG_VALGRIND=1 to enable' unless $ENV{EV_PG_VALGRIND};
plan skip_all => 'valgrind not in PATH' unless `which valgrind` =~ /\S/;
plan skip_all => 'set TEST_PG_CONNINFO' unless $ENV{TEST_PG_CONNINFO};

plan tests => 2;

my (undef, $logfile) = tempfile('ev_pg_vg_XXXXXX', SUFFIX => '.log',
                                TMPDIR => 1, UNLINK => 0);

my (undef, $childlog) = tempfile('ev_pg_vg_child_XXXXXX', SUFFIX => '.log',
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
    $^X, '-Iblib/lib', '-Iblib/arch', 't/05_leak.t',
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
