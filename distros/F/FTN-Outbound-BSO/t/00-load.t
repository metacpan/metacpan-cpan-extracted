#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok( 'FTN::Outbound::BSO' );
}

diag( "Testing FTN::Outbound::BSO $FTN::Outbound::BSO::VERSION, Perl $], $^X" );
