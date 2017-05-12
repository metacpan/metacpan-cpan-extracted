#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::Table::FromDatabase' );
}

diag( "Testing HTML::Table::FromDatabase "
    . "$HTML::Table::FromDatabase::VERSION, Perl $], $^X" );
