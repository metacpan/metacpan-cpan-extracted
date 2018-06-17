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

my $log_file = catfile(qw/t Moose Instrument HP34420A.yml/);

my $dmm = mock_instrument(
    type     => 'HP34420A',
    log_file => $log_file,
);

# Test getters and setters

scpi_set_get_test(
    instr      => $dmm,
    func       => 'route_terminals',
    values     => [qw/FRON2 FRON/],
    is_numeric => 0,
);

$dmm->route_terminals( value => 'FRON1' );

scpi_set_get_test(
    instr      => $dmm,
    func       => 'sense_function',
    values     => [qw/VOLT RES/],
    is_numeric => 0,
);

# Voltage ranges
$dmm->sense_function( value => 'VOLT' );
scpi_set_get_test(
    instr  => $dmm,
    func   => 'sense_range',
    values => [ 0.001, 0.1, 1, 10 ]
);

scpi_set_get_test(
    instr  => $dmm,
    func   => 'sense_nplc',
    values => [ 0.02, 0.2, 1, 2, 10, 100 ],
);

$dmm->sense_range( value => 0.1 );
$dmm->sense_nplc( value => 10 );

my $value = $dmm->get_value();
is_absolute_error( $value, 0, 5e-4, "read voltage value" );

$dmm->rst();
done_testing();
