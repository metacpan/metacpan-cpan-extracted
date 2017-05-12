#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok( 'FTN::Bit_flags' );
}

diag( "Testing FTN::Bit_flags $FTN::Bit_flags::VERSION, Perl $], $^X" );
