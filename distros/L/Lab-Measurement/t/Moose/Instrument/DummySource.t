#!perl

use warnings;
use strict;
use 5.010;
use lib 't';
use Test::More;
use Lab::Test import => [qw/is_absolute_error/];
use Time::HiRes qw/time sleep/;
use Lab::Moose;

my $source = instrument(
    type                 => 'DummySource',
    connection_type      => 'Debug',
    connection_options   => { verbose => 0 },
    verbose              => 0,
    max_units            => 100,
    min_units            => -10,
    max_units_per_step   => 100,
    max_units_per_second => 1000000,
);

# sweep to 10 in 5 seconds
my $target = 10;
my $rate   = 2;

is( $source->get_level(), 0, "source is at 0" );

$source->config_sweep( point => $target, rate => $rate );
$source->trg();

is( $source->active(), 1, "source is active" );
my $t1 = 1;
sleep($t1);

my $delta_t = 0.5;

my $level = $source->get_level();
is_absolute_error( $level, $t1 * $rate, $rate * $delta_t, "level is $level" );

my $t2 = 3;
sleep($t2);

# one second before sweep is finished
$level = $source->get_level();
is_absolute_error(
    $level, ( $t1 + $t2 ) * $rate, $rate * $delta_t,
    "level is $level"
);

sleep(2);

# sweep should be finished now, level at end point
is( $source->active(),    0,       "source not active" );
is( $source->get_level(), $target, "level at target value" );

# Fast sweep back to zero in 2 seconds
$rate   = 5;
$target = 0;
$source->config_sweep( point => $target, rate => $rate );
$source->trg();
sleep(1);
$level = $source->get_level();
is_absolute_error( $level, 5, $rate * $delta_t, "source is at $level" );
$source->wait();
is( $source->active(),  0, "source not active" );
is( $source->get_level, 0, "source at 0" );

done_testing();

