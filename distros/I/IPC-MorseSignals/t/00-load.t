#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
	use_ok( 'IPC::MorseSignals' );
 use_ok( 'IPC::MorseSignals::Emitter' );
 use_ok( 'IPC::MorseSignals::Receiver' );
}

diag( "Testing IPC::MorseSignals $IPC::MorseSignals::VERSION, Perl $], $^X" );
