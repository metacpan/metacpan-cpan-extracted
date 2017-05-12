#!perl
use strict;
use warnings;
use Test::More 'no_plan';

# Setup:
#   in Ref,   constant rate of 1
#   in Alpha, rate of 1 from 0 to 100, 2   from 100 to 200, 1.5 from 200 on
#   in Beta,  rate of 1 from 0 to 100, 0.5 from 100 to 175, 1   from 175 on

use Math::VarRate;

my %meter = (
  ref   => Math::VarRate->new({ rate_changes => { 0 => 1 } }),
  alpha => Math::VarRate->new({
    rate_changes => {
      0   => 1,
      100 => 2.0,
      200 => 1.5,
    },
  }),
  beta  => Math::VarRate->new({
    rate_changes => {
      0   => 1,
      100 => 0.5,
      175 => 1,
    },
  }),
);

isa_ok($meter{$_}, 'Math::VarRate') for keys %meter;

is($meter{$_}->value_at(0),  0,  "$_ meter: 0 at 0") for keys %meter;
is($meter{$_}->value_at(50), 50, "$_ meter: 50 at 50") for keys %meter;

is(
  $meter{ref}->value_at(300),
  300,
  "ref meter: 300 at 300",
);

is(
  $meter{alpha}->value_at(300),
  450,
  "alpha meter: 450 at 300",
);

is(
  $meter{beta}->value_at(300),
  262.5,
  "beta meter: 262.5 at 300",
);

is($meter{ref}->offset_for(300),    300, "ref meter: 300 at 300 (value_at)");
is($meter{alpha}->offset_for(450),  300, "ref meter: 450 at 300 (value_at)");
is($meter{beta}->offset_for(262.5), 300, "ref meter: 262.5 at 300 (value_at)");

my $stopper = Math::VarRate->new({
  rate_changes => {
    10 => 1,
    20 => 0,
  },
});

is($stopper->value_at(0),  0,  "stopper: start at 0");
is($stopper->value_at(5),  0,  "stopper: still 0 at 5");
is($stopper->value_at(10), 0,  "stopper: still 0 at 10");
is($stopper->value_at(11), 1,  "stopper: after 11, value is 1");
is($stopper->value_at(25), 10, "stopper: after 25, value stopped at 10");

is($stopper->offset_for(0),   0, "stopper: we start at 0");
is($stopper->offset_for(1),  11, "stopper: we reach 1 at 11");
is($stopper->offset_for(10), 20, "stopper: we reach 10 at 20");
is($stopper->offset_for(11), undef, "stopper: we never reach 11");

my $stagnant = Math::VarRate->new;
is($stagnant->offset_for(0),    0, "stagnant: starts at 0");
is($stagnant->value_at(10_000), 0, "stagnant: never moves");
