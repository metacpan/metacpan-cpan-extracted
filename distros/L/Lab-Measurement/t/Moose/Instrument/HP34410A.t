#!perl

use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test import => [qw/scpi_set_get_test is_absolute_error/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;
use MooseX::Params::Validate;
use File::Spec::Functions 'catfile';
use Data::Dumper;

my $log_file = catfile(qw/t Moose Instrument HP34410A.yml/);

my $dmm = mock_instrument(
    type     => 'HP34410A',
    log_file => $log_file,
);

# Test getters and setters

scpi_set_get_test(
    instr      => $dmm,
    func       => 'sense_function',
    values     => [qw/CURR VOLT/],
    is_numeric => 0,
);

# Voltage ranges
$dmm->sense_function( value => 'VOLT' );
scpi_set_get_test(
    instr  => $dmm,
    func   => 'sense_range',
    values => [ 0.1, 1, 10, 100, 1000 ]
);

# Current ranges
$dmm->sense_function( value => 'CURR' );
scpi_set_get_test(
    instr  => $dmm,
    func   => 'sense_range',
    values => [ 100e-6, 1e-3, 10e-3, 100e-3, 1 ]
);

scpi_set_get_test(
    instr  => $dmm,
    func   => 'sense_nplc',
    values => [ 0.006, 0.02, 0.06, 0.2, 1, 2, 10, 100 ],
);

$dmm->sense_function( value => 'VOLT' );
$dmm->sense_range( value => 0.1 );
$dmm->sense_nplc( value => 10 );
my $value = $dmm->get_value();
is_absolute_error( $value, 0, 5e-4, "read voltage value" );

$dmm->rst();
done_testing();
