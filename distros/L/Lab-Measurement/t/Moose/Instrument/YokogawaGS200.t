#!perl

use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test import => [qw/scpi_set_get_test is_float/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;
use MooseX::Params::Validate;
use File::Spec::Functions 'catfile';
use Data::Dumper;

my $log_file = catfile(qw/t Moose Instrument YokogawaGS200.yml/);

my $yoko = mock_instrument(
    type               => 'YokogawaGS200',
    log_file           => $log_file,
    instrument_options => {

        # linear_step_sweep output interferes with TAP
        verbose              => 0,
        max_units            => 10,
        min_units            => -10,
        max_units_per_step   => 0.1,
        max_units_per_second => 10
        }

);

# Test getters and setters

# Source function

scpi_set_get_test(
    instr      => $yoko,
    func       => 'source_function',
    values     => [qw/CURR VOLT/],
    is_numeric => 0,
);

scpi_set_get_test(
    instr  => $yoko,
    func   => 'source_range',
    values => [qw/10e-3 1 10 30/],
);

scpi_set_get_test(
    instr  => $yoko,
    func   => 'source_level',
    values => [qw/1.111 2.222 3.333/],
);
$yoko->source_level( value => 0 );

# Basic sweep, should use 10 steps.
my $target = 1.234;
$yoko->set_level( value => $target );
is_float( $yoko->cached_level(), $target, "cached level" );
is_float( $yoko->get_level(),    $target, "get_level" );

$yoko->rst();
done_testing();
