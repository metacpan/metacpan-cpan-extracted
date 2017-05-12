#!/usr/bin/env perl

use 5.010;
use warnings;
use strict;

use lib 't/';
use Test::More;
use Lab::Measurement;
use Lab::Test import => [qw/is_float skip_on_broken_printf/];

use Scalar::Util qw(looks_like_number);

use MockTest;

skip_on_broken_printf();

my $query;
my $yoko = Instrument(
    'Yokogawa7651',
    {
        connection_type => get_connection_type(),
        gpib_address    => get_gpib_address(11),
        logfile         => get_logfile('t/Instrument/Yokogawa7651.yml'),
        gate_protect    => 0,
    }
);

# function

for my $function (qw/current voltage/) {
    $yoko->set_function($function);
    my $query = $yoko->get_function();
    is( $query, $function, "function set to $function" );
}

# range
my @ranges        = qw/10e-3 100e-3 1 10 30/;
my @return_ranges = qw/12e-3 120e-3 1.2 12 32/;

for ( my $i = 0; $i < @ranges; ++$i ) {
    $yoko->set_range( $ranges[$i] );
    my $query = $yoko->get_range();
    ok( $query == $return_ranges[$i], "range set to " . $ranges[$i] );
}

# level

$yoko->set_range(1);
test_levels(qw/1 1e-2 1e-3 1e-4 1e-5  1.11111/);
$yoko->set_range(10e-3);
test_levels(qw/1e-2 1e-3 1e-4 1e-5 1e-6 0.0111111/);

done_testing();

sub test_levels {
    my @levels = @_;
    for my $level (@levels) {
        $yoko->set_level($level);
        $query = $yoko->get_level();
        is_float( $query, $level, "level set to $level" );
    }
}

