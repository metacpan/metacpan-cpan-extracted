#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use lib grep { -d $_ } qw(./lib ../lib ./t/lib);
use Functional::Utility qw(throttle);          # this is in lib/
use Test::Resub qw(resub);                     # this comes from t/lib/
use Test::Facile qw(nearly_ok nearly each_ok deep_ok); # this comes from t/lib/

# muck with Time::HiRes, which our throttler uses for high-precision timing and sleeping
use Time::HiRes ();
my $now = Time::HiRes::time;
my $rs_time = resub 'Time::HiRes::time', sub { $now };
my $rs_hires_sleep = resub 'Time::HiRes::sleep', sub { $now += pop; undef };

# In order to show that "throttle { }" actually sleeps by various factors of
# time, I need some test code that takes various amounts of time to run. I
# could just sleep, but why should you have to wait an extra 6 seconds to
# run these tests when I could just sieze control of the clock?
my @slept;
BEGIN { *CORE::GLOBAL::sleep = sub (;$) { push @slept, [@_]; $now += pop } }

# throttle with a factor => $n: we'll wait $n times as long as the previous run took before running again
my $sleep = 1;
my $run = 1;
throttle { $sleep *= $run++; sleep $sleep; } factor => 3 for 1..3;
deep_ok( \@slept, [[1], [2], [6]], 'throttled code would have slept 1, 2, then 6 seconds' );
is( $rs_hires_sleep->called, 2, 'slept twice' );
my @expected = (2, 1);
each_ok { nearly( $_->[0], shift(@expected), .1) } @{$rs_hires_sleep->args};
