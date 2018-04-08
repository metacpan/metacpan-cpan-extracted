#!perl

# Do not connect anything to the input ports when running this!!!

use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test import =>
    [qw/is_float is_absolute_error is_relative_error set_get_test/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;
use MooseX::Params::Validate;

use File::Spec::Functions 'catfile';
my $log_file = catfile(qw/t Moose Instrument SR830.yml/);

my $lia = mock_instrument(
    type     => 'SR830',
    log_file => $log_file,
);

isa_ok( $lia, 'Lab::Moose::Instrument::SR830' );

$lia->rst( timeout => 10 );

my @values;

# Get X, Y, R, phi
my $xy = $lia->get_xy( timeout => 3 );
is_absolute_error( $xy->{x}, 0, 0.001, "X is almost zero" );
is_absolute_error( $xy->{y}, 0, 0.001, "Y is almost zero" );

my $rphi = $lia->get_rphi();
is_absolute_error( $rphi->{r},   0, 0.001, "R is almost zero" );
is_absolute_error( $rphi->{phi}, 0, 180,   "phi is in [-180,180]" );

# Set/Get reference frequency

set_get_test(
    instr => $lia, getter => 'get_frq', setter => 'set_frq',
    cache => 'cached_frq', values => [qw/1 10 1000 100000/]
);

# Amplitude

set_get_test(
    instr  => $lia,            getter => 'get_amplitude',
    setter => 'set_amplitude', cache  => 'cached_amplitude',
    values => [qw/0.004 1 2 3 5/]
);

# Phase

set_get_test(
    instr  => $lia,        getter => 'get_phase',
    setter => 'set_phase', cache  => 'cached_phase',
    values => [qw/-179 90 0 45 90 179/]
);

# Time constant
set_get_test(
    instr  => $lia,     getter => 'get_tc',
    setter => 'set_tc', cache  => 'cached_tc',
    values => [qw/1e-5 3e-5 1e-4 1 10 30/]
);

# Filter slope

set_get_test(
    instr  => $lia,               getter => 'get_filter_slope',
    setter => 'set_filter_slope', cache  => 'cached_filter_slope',
    values => [qw/6 12 18 24/]
);

# Sensitivity

set_get_test(
    instr  => $lia,       getter => 'get_sens',
    setter => 'set_sens', cache  => 'cached_sens',
    values => [qw/1 0.5 0.2 0.1 0.05 1e-5 2e-5 5e-5/]
);

# Inputs
# I100M only available if sens is <= 5mV

$lia->set_sens( value => 5e-3 );

set_get_test(
    instr  => $lia,                 getter     => 'get_input',
    setter => 'set_input',          cache      => 'cached_input',
    values => [qw/A AB I1M I100M/], is_numeric => 0
);

# Grounding

set_get_test(
    instr  => $lia,               getter     => 'get_ground',
    setter => 'set_ground',       cache      => 'cached_ground',
    values => [qw/GROUND FLOAT/], is_numeric => 0
);

# Coupling

set_get_test(
    instr  => $lia,           getter     => 'get_coupling',
    setter => 'set_coupling', cache      => 'cached_coupling',
    values => [qw/AC DC/],    is_numeric => 0
);

# Line notch filters.

set_get_test(
    instr  => $lia, getter => 'get_line_notch_filters',
    setter => 'set_line_notch_filters',
    cache  => 'cached_line_notch_filters',
    values => [qw/OUT LINE 2xLINE BOTH/], is_numeric => 0
);

# Settling time

$lia->set_tc( value => 1 );
$lia->set_filter_slope( value => 6 );

is_float(
    $lia->calculate_settling_time( settling => 90 ), 2.3,
    "settling time tc=1, slope=6, settling=90"
);

$lia->set_tc( value => 0.1 );
$lia->set_filter_slope( value => 18 );

is_float(
    $lia->calculate_settling_time( settling => 99 ), 0.1 * 8.41,
    "settling time tc=0.1, slope=18, settling=99"
);
is_float(
    $lia->calculate_settling_time( settling => 63.2 ), 0.1 * 3.26,
    "settling time tc=0.1, slope=18, settling=63.2"
);

$lia->rst();
done_testing();
