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

my $log_file = catfile(qw/t Moose Instrument KeysightB2901A.yml/);

my $b2901a = mock_instrument(
    type     => 'KeysightB2901A',
    log_file => $log_file,

    # linear_step_sweep output interferes with TAP
    verbose              => 0,
    max_units            => 10,
    min_units            => -10,
    max_units_per_step   => 0.1,
    max_units_per_second => 10
);

$b2901a->rst();

# Test getters and setters

# Sense subsystem

$b2901a->sense_function_off( value => [ 'VOLT', 'CURR' ] );
my $functions = $b2901a->sense_function_on_query();
is_deeply( $functions, [], 'All functions off' );

$b2901a->sense_function_on( value => ['CURR'] );
$functions = $b2901a->sense_function_on_query();

is_deeply( $functions, ['CURR'], 'Set function to CURR' );

$b2901a->sense_function_off( value => ['CURR'] );
$b2901a->sense_function_on( value => ['VOLT'] );
$functions = $b2901a->sense_function_on_query();
print Dumper($functions);
is_deeply( $functions, ['VOLT'], 'Set function to VOLT' );

$b2901a->sense_function_on( value => ['CURR'] );
$b2901a->sense_function( value => 'CURR' );

scpi_set_get_test(
    instr  => $b2901a,
    func   => 'sense_range',
    values => [qw/1e-6 1e-5 1e-4/],
);

scpi_set_get_test(
    instr  => $b2901a,
    func   => 'sense_protection',
    values => [qw/1e-6 1e-5 1e-4/]
);

# Source subsystem

scpi_set_get_test(
    instr      => $b2901a,
    func       => 'source_function',
    values     => [qw/CURR VOLT/],
    is_numeric => 0,
);

scpi_set_get_test(
    instr  => $b2901a,
    func   => 'source_range',
    values => [qw/0.2 2 20 200/],
);

$b2901a->source_range( value => 21 );

scpi_set_get_test(
    instr  => $b2901a,
    func   => 'source_level',
    values => [qw/1.111 2.222 3.333/],
);
$b2901a->source_level( value => 0 );

# Basic sweep, should use 10 steps.
my $target = 1.234;
$b2901a->set_level( value => $target );
is_float( $b2901a->cached_level(), $target, "cached level" );
is_float( $b2901a->get_level(),    $target, "get_level" );

is( $b2901a->sense_protection_tripped_query(), 0, "source is not tripped" );

$b2901a->rst();

done_testing();
