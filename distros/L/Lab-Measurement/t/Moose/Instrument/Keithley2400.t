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

my $log_file = catfile(qw/t Moose Instrument Keithley2400.yml/);

my $keithley = mock_instrument(
    type     => 'Keithley2400',
    log_file => $log_file,

    # linear_step_sweep output interferes with TAP
    verbose              => 0,
    max_units            => 10,
    min_units            => -10,
    max_units_per_step   => 0.1,
    max_units_per_second => 10
);

$keithley->rst();
$keithley->sense_function_concurrent( value => 0 );
# Test getters and setters

# Sense subsystem

scpi_set_get_test(
    instr  => $keithley,
    func   => 'sense_function_concurrent',
    values => [ 0, 1 ]
);

$keithley->sense_function_concurrent( value => 0 );


$keithley->sense_function_on(value => ['CURR:DC']);
my $functions = $keithley->sense_function_on_query();
is_deeply($functions, ['CURR:DC'], 'Set function to CURR:DC');


$keithley->sense_function_on(value => ['VOLT:DC']);
$functions = $keithley->sense_function_on_query();
is_deeply($functions, ['VOLT:DC'], 'Set function to VOLT:DC');



# scpi_set_get_test(
#     instr      => $keithley,
#     func       => 'sense_function_on',
#     values     => [['CURR:DC'],['VOLT:DC']],
#     is_numeric => 0
# );

$keithley->sense_function_on( value => ['CURR'] );
$keithley->sense_function( value => 'CURR' );

scpi_set_get_test(
    instr  => $keithley,
    func   => 'sense_range',
    values => [qw/1.05e-6 1.05e-5 1.05e-4/],
);

scpi_set_get_test(
    instr  => $keithley,
    func   => 'sense_protection',
    values => [qw/1e-6 1e-5 1e-4/]
);

# Source subsystem

scpi_set_get_test(
    instr      => $keithley,
    func       => 'source_function',
    values     => [qw/CURR VOLT/],
    is_numeric => 0,
);

scpi_set_get_test(
    instr  => $keithley,
    func   => 'source_range',
    values => [qw/0.21 2.1 21 210/],
);

$keithley->source_range( value => 21 );

scpi_set_get_test(
    instr  => $keithley,
    func   => 'source_level',
    values => [qw/1.111 2.222 3.333/],
);
$keithley->source_level( value => 0 );

# Basic sweep, should use 10 steps.
my $target = 1.234;
$keithley->set_level( value => $target );
is_float( $keithley->cached_level(), $target, "cached level" );
is_float( $keithley->get_level(),    $target, "get_level" );

is( $keithley->sense_protection_tripped_query(), 0, "source is not tripped" );

$keithley->rst();

done_testing();
