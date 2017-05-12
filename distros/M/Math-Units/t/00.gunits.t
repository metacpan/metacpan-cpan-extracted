#!/usr/bin/perl -w

use strict;
use Test::More;
use Math::Units;

system 'gunits', '-v';
plan 'skip_all' => 'gunits program required for these tests' if $? == -1;
plan 'no_plan';

sub test_conversion_against_gunits {
    my ( $value, $u1, $u2 ) = @_;

    my $my_result = Math::Units::convert( $value, $u1, $u2 );
    my $rounded_result = sprintf( "%.10g", $my_result );

    diag "*** CONVERTED $value '$u1' to $my_result '$u2' ($rounded_result)\n";
    diag "    '$value\@$u1\@$u2' => $rounded_result, #--R--\n";

    my $gunits_output = `gunits --output-format %.10g --silent '$value $u1' '$u2'`;

    if ( $gunits_output =~ /\* (.*)/ ) {
        my $gunits_result = $1;

        my $err = $gunits_result - $my_result;
        ok( $gunits_result == $rounded_result, "gunits - $value $u1 => $u2" );

        if ( $gunits_result != $rounded_result ) {
            diag "For the input : $value $u1 => $u2\n";
            diag "     my result : $rounded_result ($my_result)\n";
            diag " gunits result : $gunits_result\n";
            diag "         error : $err\n";
        }
    }
    else {
        diag "gunits was not able to convert $value $u1 => $u2";
    }
}

sub doit ($$$) {
    my ( $v, $source, $target ) = @_;
    test_conversion_against_gunits( $v, $source, $target );
}

for ( 1 .. 3 ) {

    doit( 100,  "ton",  "tonne" );
    doit( 10,   "ton",  "lb" );
    doit( 10,   "tonf", "lbf" );
    doit( 50,   "N",    "lbf" );
    doit( 9990, "N",    "tonf" );

    doit( 2000, "rpm", "Hz" );
    doit( 2000, "rpm", "cycle/min" );
    doit( 2000, "rpm", "deg/sec" );

    doit( 87,    "jerk", "N/kg sec" );
    doit( 123,   'jerk', 'N/kg sec' );
    doit( 12000, 'jerk', 'lbf/ton sec' );

    doit( 123,   "meters per second per second", "yd/s/s" );
    doit( 123,   "5^2/m^2",                      "25 m^-1/m" );
    doit( 220,   "K",                            "F" );
    doit( 20,    "C",                            "F" );
    doit( 2,     "Cd",                           "Fd" );
    doit( 1,     "m/Cd",                         "in/Fd" );
    doit( 1,     "m",                            "in" );
    doit( 50,    "hectare",                      "ft^2" );
    doit( 1,     "m/s",                          "ft/s" );
    doit( 100,   "ft/sec",                       "ft/min" );
    doit( 100,   "km/hr",                        "mi/hr" );
    doit( 1,     "Pa/Hz",                        "Pa/kHz" );
    doit( 1,     "N",                            "lb in/s^2" );
    doit( 2789,  "in m",                         "are" );
    doit( 1,     "hp",                           "m N/s" );
    doit( 1,     "m m",                          "ft yd" );
    doit( 1,     "l",                            "qt" );
    doit( 8,     "ft lbf/s",                     "W" );
    doit( 89,    "kg/m m",                       "lb/in ft" );
    doit( 167,   "N",                            "lbf" );
    doit( 278,   "N^2",                          "lbf^2" );
    doit( 1,     "25 barrel^2",                  "floz^2" );
    doit( 0.1,   "F^-1",                         "C^-1" );
    doit( 1,     "m s^-1",                       "ft s^-1" );
    doit( 1,     "l",                            "qt" );
    doit( 1,     "m^3",                          "gal" );
    doit( 100,   "in^3",                         "qt" );
    doit( 7001,  "cc",                           "qt" );
    doit( 1,     "m^6",                          "l^2" );
    doit( 786,   "m in",                         "ft yd" );
    doit( 786,   "m in",                         "ft yd" );
    doit( 1,     "lbf",                          "N" );
    doit( 10,    "m/Cd",                         "m/Fd" );
    doit( 55550, "angstroms",                    "microns" );
    doit( 5e12,  "angstroms",                    "in" );
    doit( 9000,  "Hz",                           "kHz" );
    doit( 1,     "gal",                          "in^3" );
    doit( 10,    "gal",                          "pnt^3" );
    doit( 100,   "pnt^2",                        "mm^2" );
    doit( 9e9,   "pnt",                          "km" );
    doit( 100,   "ft",                           "m" );
    doit( 100,   "km/hr",                        "mi/hr" );
    doit( 100,   "ft/sec",                       "ft/min" );
    doit( 100,   "ft/sec",                       "m/sec" );
    doit( 100,   "feet per second squared",      "ft/min^2" );
    doit( 100,   "ft/sec",                       "m/sec" );
    doit( 1,     "N^2",                          "g^2 km^2/s^4" );
    doit( 17,    "N",                            "lb in/s^2" );
    doit( 212,   "F",                            "C" );
    doit( 32,    "F",                            "C" );
    doit( 70,    "F",                            "C" );
    doit( 98.6,  "F",                            "C" );
    doit( 1e20,  "cubic microns",                "cubic inches" );
    doit( 980,   "microns",                      "milliinches" );
    doit( 9700,  "microns",                      "milli-inches" );
    doit( 8976,  "microns",                      "m-in" );
    doit( 4500,  "cc",                           "l" );
    doit( 500,   "in^3",                         "l" );
    doit( 500,   "in^3",                         "qt" );
    doit( 17896, "m^2/m m^3",                    "in in/in^4" );

}

my @prefixes = ( 'giga', 'mega', 'kilo', 'hecto', '', 'deci', 'centi', 'milli', 'micro' );

my @base_source = ( 'in', 'ft', 'yd', 'mi' );
my @base_target = ( 'm', 'ft' );

for my $exp ( 1 .. 4 ) {
    foreach my $b_source (@base_source) {
        foreach my $b_target (@base_target) {
            foreach my $pre_source (@prefixes) {
                foreach my $pre_target (@prefixes) {
                    if ( $exp == 1 ) {
                        doit( 2, "$pre_source$b_source", "$pre_target$b_target" );
                    }
                    else {
                        doit( 2, "$pre_source$b_source^$exp", "$pre_target$b_target^$exp" );
                    }
                }
            }
        }
    }
}
