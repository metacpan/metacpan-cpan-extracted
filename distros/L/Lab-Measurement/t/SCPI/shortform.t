#!perl -T 
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 6;

#BEGIN {
#    # need these to make system() calls in testing while taint check on
#    $ENV{PATH} = '/usr/bin';
#    $ENV{BASH_ENV} = '';
#
#}

use_ok('Lab::SCPI') || print "Bail out!\n";

# scpi_shortform not exported, use explicit package name

is( Lab::SCPI::scpi_shortform('CHANNEL'), 'CHAN', 'truncate to 4' );
is( Lab::SCPI::scpi_shortform('input'),   'inp',  'truncate to 3' );
is(
    Lab::SCPI::scpi_shortform('TRIGGER3'), 'TRIG3',
    '4 with trailing number'
);
is(
    Lab::SCPI::scpi_shortform('waveform7'), 'wav7',
    '3 with trailing number'
);
is( Lab::SCPI::scpi_shortform('*trg'), '*trg', 'handle common command form' );

