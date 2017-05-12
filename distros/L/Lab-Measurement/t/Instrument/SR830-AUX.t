#!/usr/bin/env perl

# before you run this with a real instrument, connect AUX OUT 1 with AUX IN 1 and AUX OUT 2 with AUX
# IN 2.

use 5.010;
use warnings;
use strict;

use lib qw(t/);
use Lab::Test import => [qw/is_num is_relative_error/];
use Test::More tests => 4;

use Lab::Measurement;

use MockTest;

my $connection = Connection(
    get_connection_type(),
    {
        gpib_address => get_gpib_address(8),
        logfile      => get_logfile('t/Instrument/SR830-AUX.yml')
    }
);

my $input1 = Instrument(
    'SR830::AuxIn',
    {
        connection => $connection,
        channel    => 1,
    }
);

my $input2 = Instrument(
    'SR830::AuxIn',
    {
        connection => $connection,
        channel    => 2,
    }
);

my $output1 = Instrument(
    'SR830::AuxOut',
    {
        connection   => $connection,
        gate_protect => 0,
        channel      => 1,
    }
);

my $output2 = Instrument(
    'SR830::AuxOut',
    {
        connection   => $connection,
        gate_protect => 0,
        channel      => 2,
    }
);

my $level;

# set output values:
$output1->set_level(1.111);
$output2->set_level(2.222);

# get output values:
$level = $output1->get_level();
is_num( $level, 1.111, 'output 1 is set' );

$level = $output2->get_level();
is_num( $level, 2.222, 'output 2 is set' );

# read inputs
$level = $input1->get_value();

is_relative_error( $level, 1.111, 1 / 50, 'voltage is set at input 1' );

$level = $input2->get_value();

is_relative_error( $level, 2.222, 1 / 50, 'voltage is set at input 2' );
