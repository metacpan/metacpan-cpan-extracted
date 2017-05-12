#!perl

use 5.010;
use warnings;
use strict;

use Test::More tests => 1;

use Lab::Measurement;

my $vna = Instrument(
    'RS_ZVA', {
        connection_type => 'Debug',
        timeout         => 2
    }
);

isa_ok( $vna, 'Lab::Moose::Instrument::RS_ZVA' );
