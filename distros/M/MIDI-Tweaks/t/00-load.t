#! perl

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok( 'MIDI::Tweaks' );
}

-d "t" && chdir "t";
require_ok("./tools.pl");

diag( "Testing MIDI::Tweaks $MIDI::Tweaks::VERSION, Perl $], $^X" );
