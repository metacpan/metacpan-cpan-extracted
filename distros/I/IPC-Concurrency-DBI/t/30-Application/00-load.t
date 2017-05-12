#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'IPC::Concurrency::DBI::Application' ) || print "Bail out!\n";
}

diag( "IPC::Concurrency::DBI::Application $IPC::Concurrency::DBI::Application::VERSION, Perl $], $^X" );
