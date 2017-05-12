#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;
use lib qw(t/);
use Data::Dumper;
use Test::More tests => 20;

use Lab::Measurement;
use Scalar::Util qw(looks_like_number);

use MockTest;
use Lab::Test import => [
    qw/
        looks_like_number_ok
        is_num
        is_relative_error
        /
];

my $function;

my $multimeter = Instrument(
    'Agilent34410A',
    {
        connection_type => get_connection_type(),
        gpib_address    => get_gpib_address(17),
        logfile         => get_logfile('t/Instrument/Agilent34410A.yml')
    }
);

#reset

$multimeter->set_function('volt:ac');
$multimeter->reset();
$function = $multimeter->get_function();
is( $function, 'VOLT', 'function is VOLT after reset' );

# get_value

my $value = $multimeter->get_value();
looks_like_number_ok( $value, "get_value returns a number" );

# set_function / get_function

$multimeter->set_function('volt:ac');
$function = $multimeter->get_function();
is( $function, 'VOLT:AC', 'function changed to volt:ac' );
$multimeter->set_function('VOLT');

# get_function

$function = $multimeter->get_function();
is( $function, 'VOLT', 'get_function returns VOLT' );
$function = $multimeter->get_function( { read_mode => 'cache' } );
is( $function, 'VOLT', 'cached get_function returns VOLT' );

# in list context FIXME: list commit hash

my @function = $multimeter->get_function();
is( $function[0], 'VOLT', 'get_function returns VOLT' );
$function = $multimeter->get_function( { read_mode => 'cache' } );
is( $function, 'VOLT', 'cached get_function returns VOLT' );

# set_range / get_range
sub range_test {
    for my $array_ref (@_) {
        my $value    = $array_ref->[0];
        my $expected = $array_ref->[1];

        $multimeter->set_range($value);
        my $result = $multimeter->get_range();
        is_num( $result, $expected, "range set to $expected" );
    }
}

#fixme: def min max are broken??
range_test(
    [ 0.1,   0.1 ],
    [ 1,     1 ],
    [ 1000,  1000 ],
    [ 'def', 10 ],
    [ 'min', 0.1 ],
    [ 'max', 1000 ]
);

# in current mode
$multimeter->set_function('current');
range_test( [ 1, 1 ], [ 3, 3 ] );

# autoranging
$multimeter->set_range('auto');
my $autorange = $multimeter->get_autorange();
is( $autorange, 1, "autorange enabled" );

# disable autoranging
$multimeter->set_range('1');
$autorange = $multimeter->get_autorange();
is( $autorange, 0, "autorange disabled" );

# set_nplc / get_nplc
$multimeter->set_function('volt');
$multimeter->set_nplc(2);
my $nplc = $multimeter->get_nplc();
is_num( $nplc, 2, "nplc set to 2" );

# # get_resolution / set_resolution

# $multimeter->set_resolution(2);
# my $resolution = $multimeter->get_resolution();
# ok ($resolution == 2, "resolution $resolution");

# get_tc / set_tc

$multimeter->set_tc(0.5);
my $tc = $multimeter->get_tc();
is_relative_error( $tc, 0.5, 0.0001, "tc set to 0.5" );

# get_bw / set_bw
$multimeter->set_function('volt:ac');
$multimeter->set_bw(200);
my $bw = $multimeter->get_bw();
is_num( $bw, 200, "bw is set to 200" );

