#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use lib grep { -d $_ } qw(./lib ../lib ./t/lib);
use Functional::Utility qw(throttle);  # this is in lib/
use Test::Resub qw(resub);             # this comes from t/lib/
use Test::Facile qw(nearly each_ok);   # this comes from t/lib/

# Declare our intent to muck with Perl's sleep() function. This is
# much less verbose on versions of Perl < 5.16, because a resub can
# just handle it.
my @slept;
BEGIN { *CORE::GLOBAL::sleep = sub (;$) { push @slept, [@_] } }

# Monkeypatch Time::HiRes::sleep. (The use line aids tdd, and catches weird regressions
# due to bad merge conflict resolution.)
use Time::HiRes ();
my $rs_hires_sleep = resub 'Time::HiRes::sleep', sub {};

# throttle with a delay => $n: we'll wait $n seconds between runs
my $sleep = 1;
my @times;
throttle { sleep $sleep++ } delay => .5 for 1..3;
is_deeply( \@slept, [[1], [2], [3]], 'throttled code would have slept 1, 2, then 3 seconds' );
each_ok { nearly($_->[0], .5, .1) } @{$rs_hires_sleep->args};
is( $rs_hires_sleep->called, 2, 'we slept twice' );
