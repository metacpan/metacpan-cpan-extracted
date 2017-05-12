#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'IPC::Concurrency::DBI' ) || print "Bail out!\n";
}

diag( "IPC::Concurrency::DBI $IPC::Concurrency::DBI::VERSION, Perl $], $^X" );
