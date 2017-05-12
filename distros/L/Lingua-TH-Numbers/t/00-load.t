#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Lingua::TH::Numbers' ) || print "Bail out!\n";
}

diag( "Testing Lingua::TH::Numbers $Lingua::TH::Numbers::VERSION, Perl $], $^X" );
