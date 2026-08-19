#!/usr/bin/env perl
# Author test: re-run the suite under valgrind and fail on definite leaks or
# memory errors. Skipped unless EV_YACURL_VALGRIND=1, so `make test` is
# unaffected.

use strict;
use warnings;
use Config;
use File::Temp qw(tempfile);
use POSIX ();
use Test::More;

plan skip_all => 'set EV_YACURL_VALGRIND=1 to enable' unless $ENV{EV_YACURL_VALGRIND};
plan skip_all => 'valgrind not in PATH'               unless `which valgrind 2>/dev/null` =~ /\S/;

my @suite = sort glob 't/*.t';
plan tests => scalar @suite;

for my $test (@suite) {
    my (undef, $vglog)    = tempfile('ev_yacurl_vg_XXXXXX',    SUFFIX => '.log', TMPDIR => 1, UNLINK => 1);
    my (undef, $childlog) = tempfile('ev_yacurl_child_XXXXXX', SUFFIX => '.log', TMPDIR => 1, UNLINK => 1);

    my @cmd = (
        qw(valgrind
           --error-exitcode=99
           --leak-check=full
           --show-leak-kinds=definite
           --errors-for-leak-kinds=definite
           --num-callers=30
           --child-silent-after-fork=yes),
        "--log-file=$vglog",
        # $^X can be a wrapper script, which is what would get traced.
        $Config{perlpath}, '-Iblib/lib', '-Iblib/arch', $test,
    );

    # The inner test writes TAP of its own, which must not reach this stream.
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        open STDOUT, '>', $childlog or POSIX::_exit(127);
        open STDERR, '>&', \*STDOUT or POSIX::_exit(127);
        exec(@cmd) or POSIX::_exit(127);
    }
    waitpid $pid, 0;

    # A valgrind killed by a signal exits 0 through >> 8, which would pass.
    my $status = ($? & 127) ? 128 + ($? & 127) : $? >> 8;

    if ($status) {
        for my $log ($childlog, $vglog) {
            open my $fh, '<', $log or next;
            diag do { local $/; <$fh> };
        }
    }

    is($status, 0, "$test is clean under valgrind");
}
