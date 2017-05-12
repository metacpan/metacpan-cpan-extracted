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
my $barrier_l = exp(-6);
my $barrier_h = 1.36;

# call
my $price_call = Math::Business::BlackScholes::Binaries::call($S, $barrier_l, 7 / 365, 0.002, 0.001, 0.11);
ok(roundnear(0.01, $price_call) == 1, 'call (' . $price_call . ') -> 1');

# put
my $price_put = Math::Business::BlackScholes::Binaries::put($S, $barrier_l, 7 / 365, 0.002, 0.001, 0.11);
ok(roundnear(0.01, $price_put) == 0, 'put (' . $price_put . ') -> 0');

# onetouch
my $price_onetouch = Math::Business::BlackScholes::Binaries::onetouch($S, $barrier_l, 7 / 365, 0.002, 0.001, 0.11);
ok(roundnear(0.01, $price_onetouch) == 0, 'onetouch (' . $price_onetouch . ') -> 0');

# notouch
my $price_notouch = Math::Business::BlackScholes::Binaries::notouch($S, $barrier_l, 7 / 365, 0.002, 0.001, 0.11);
ok(roundnear(0.01, $price_notouch) == 1, 'notouch (' . $price_notouch . ') -> 1');

# upordown
my $price_upordown = Math::Business::BlackScholes::Binaries::upordown($S, $barrier_h, $barrier_l, 7 / 365, 0.002, 0.001, 0.11);

# onetouch at higher barrier
my $price_onetouch_higher_barrier = Math::Business::BlackScholes::Binaries::onetouch($S, $barrier_h, 7 / 365, 0.002, 0.001, 0.11);

ok($price_upordown == $price_onetouch_higher_barrier, 'upordown (lower barrier) -> onetouch (higher barrier)');

# range
my $price_range = Math::Business::BlackScholes::Binaries::range($S, $barrier_h, $barrier_l, 7 / 365, 0.002, 0.001, 0.11);
# notouch at higher barrier
my $price_notouch_higher_barrier = Math::Business::BlackScholes::Binaries::notouch($S, $barrier_h, 7 / 365, 0.002, 0.001, 0.11);
ok($price_range == $price_notouch_higher_barrier, 'range (lower barrier) -> notouch (higher barrier)');

Test::NoWarnings::had_no_warnings();
done_testing();

