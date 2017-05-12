#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok( 'FTN::Outbound::Reference_file' );
}

diag( "Testing FTN::Outbound::Reference_file $FTN::Outbound::Reference_file::VERSION, Perl $], $^X" );
