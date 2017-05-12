#!perl
use 5.010;
use warnings;
use strict;
use Data::Dumper;
use lib 't';
use Lab::Test tests => 2, import => ['is_num'];
use Lab::Measurement;

my $source = Instrument(
    'DummySource',
    {
        connection_type => 'DEBUG',
        gate_protect    => 0
    }
);

# set/get level

my $expected = 1.11;

$source->set_level($expected);

my $level = $source->get_level();

is_num( $level, $expected, "level is set" );

# set/get range

$expected = 100;

$source->set_range($expected);

my $range = $source->get_range();

is_num( $range, $expected, "range is set" );
