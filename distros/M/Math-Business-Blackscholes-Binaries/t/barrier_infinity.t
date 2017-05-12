#!/usr/bin/perl

use lib qw{ lib t/lib };
use Test::Most;
require Test::NoWarnings;
use Math::Business::BlackScholes::Binaries;
use Roundnear;

my $S         = 1.35;
my $t         = 7 / 365;
my $sigma     = 0.11;
my $r         = 0.002;
my $q         = 0.001;
my $barrier_h = exp(6);
my $barrier_l = 1.34;

# call
my $price_call = Math::Business::BlackScholes::Binaries::call($S, $barrier_h, 7 / 365, 0.002, 0.001, 0.11);
ok(roundnear(0.01, $price_call) == 0, 'call (' . $price_call . ') -> 0');

# put
my $price_put = Math::Business::BlackScholes::Binaries::put($S, $barrier_h, 7 / 365, 0.002, 0.001, 0.11);
ok(roundnear(0.01, $price_put) == 1, 'put (' . $price_put . ') -> 1');

# onetouch
my $price_onetouch = Math::Business::BlackScholes::Binaries::onetouch($S, $barrier_h, 7 / 365, 0.002, 0.001, 0.11);
ok(roundnear(0.01, $price_onetouch) == 0, 'onetouch (' . $price_onetouch . ') -> 0');

# notouch
my $price_notouch = Math::Business::BlackScholes::Binaries::notouch($S, $barrier_h, 7 / 365, 0.002, 0.001, 0.11);
ok(roundnear(0.01, $price_notouch) == 1, 'notouch (' . $price_notouch . ') -> 1');

# upordown
my $price_upordown = Math::Business::BlackScholes::Binaries::upordown($S, $barrier_h, $barrier_l, 7 / 365, 0.002, 0.001, 0.11);
# onetouch at lower barrier
my $price_onetouch_lower_barrier = Math::Business::BlackScholes::Binaries::onetouch($S, $barrier_l, 7 / 365, 0.002, 0.001, 0.11);
ok($price_upordown == $price_onetouch_lower_barrier, 'upordown (higher barrier) -> onetouch (lower barrier)');

# range
my $price_range = Math::Business::BlackScholes::Binaries::range($S, $barrier_h, $barrier_l, 7 / 365, 0.002, 0.001, 0.11);
# notouch at lower barrier
my $price_notouch_lower_barrier = Math::Business::BlackScholes::Binaries::notouch($S, $barrier_l, 7 / 365, 0.002, 0.001, 0.11);
ok($price_range == $price_notouch_lower_barrier, 'range (higher barrier) -> notouch (lower barrier)');

Test::NoWarnings::had_no_warnings();
done_testing();

