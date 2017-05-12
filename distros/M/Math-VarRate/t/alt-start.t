#!perl
use strict;
use warnings;
use Test::More 'no_plan';

# Setup:
#   everybody starts at 10
#   in Ref,   constant rate of 1
#   in Alpha, rate of 1 from 0 to 100, 2   from 100 to 200, 1.5 from 200 on
#   in Beta,  rate of 1 from 0 to 100, 0.5 from 100 to 175, 1   from 175 on

use Math::VarRate;

my %meter = (
  ref   => Math::VarRate->new({
    starting_value => 10,
    rate_changes   => { 0 => 1 },
  }),
  alpha => Math::VarRate->new({
    starting_value => 10,
    rate_changes   => {
      0   => 1,
      100 => 2.0,
      200 => 1.5,
    },
  }),
  beta  => Math::VarRate->new({
    starting_value => 10,
    rate_changes   => {
      0   => 1,
      100 => 0.5,
      175 => 1,
    },
  }),
);

isa_ok($meter{$_}, 'Math::VarRate') for keys %meter;

is($meter{$_}->starting_value, 10, "$_ meter: start at 10") for keys %meter;
is($meter{$_}->value_at(0),  10, "$_ meter: 10 at 0") for keys %meter;
is($meter{$_}->value_at(50), 60, "$_ meter: 60 at 50") for keys %meter;

is(
  $meter{ref}->value_at(300),
  310,
  "ref meter: 310 at 300",
);

is(
  $meter{alpha}->value_at(300),
  460,
  "alpha meter: 460 at 300",
);

is(
  $meter{beta}->value_at(300),
  272.5,
  "beta meter: 272.5 at 300",
);

is($meter{ref}->offset_for(310),    300, "ref meter: 310 at 300 (value_at)");
is($meter{alpha}->offset_for(460),  300, "ref meter: 460 at 300 (value_at)");
is($meter{beta}->offset_for(272.5), 300, "ref meter: 272.5 at 300 (value_at)");

is($meter{ref}->offset_for(300),    290, "ref meter: 300 at 290 (value_at)");

is(
  sprintf('%0.1f', $meter{alpha}->offset_for(450)),
  293.3,
  "ref meter: 450 at approx 293.3 (value_at)"
);

is($meter{beta}->offset_for(272.5), 300, "ref meter: 272.5 at 300 (value_at)");

my $stopper = Math::VarRate->new({
  starting_value => 10,
  rate_changes   => {
    10 => 1,
    20 => 0,
  },
});

is($stopper->value_at(0),  10, "stopper: start at 10");
is($stopper->value_at(5),  10, "stopper: still 10 at 5");
is($stopper->value_at(10), 10, "stopper: still 10 at 10");
is($stopper->value_at(11), 11, "stopper: after 11, value is 11");
is($stopper->value_at(25), 20, "stopper: after 25, value stopped at 20");

is($stopper->offset_for(0),  undef, "stopper: value is never 0");
is($stopper->offset_for(1),  undef, "stopper: value is never 0");
is($stopper->offset_for(10), 0,     "stopper: we start at 10");
is($stopper->offset_for(11), 11,    "stopper: we reach 11 at 20");
is($stopper->offset_for(21), undef, "stopper: we never reach 22");

my $stagnant = Math::VarRate->new({ starting_value => 10 });
is($stagnant->offset_for(10),    0, "stagnant: starts at 10");
is($stagnant->value_at(10_000), 10, "stagnant: never moves");
