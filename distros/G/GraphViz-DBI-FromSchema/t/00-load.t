#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'GraphViz::DBI::FromSchema' );
}

diag( "Testing GraphViz::DBI::FromSchema $GraphViz::DBI::FromSchema::VERSION, Perl $], $^X" );
