#!perl -T

use Test::More tests => 10;

BEGIN {
	use_ok( 'JQuery' );
	use_ok( 'JQuery::Accordion' );
	use_ok( 'JQuery::CSS' );
	use_ok( 'JQuery::Demo' );
	use_ok( 'JQuery::Form' );
	use_ok( 'JQuery::Splitter' );
	use_ok( 'JQuery::TableSorter' );
	use_ok( 'JQuery::Tabs' );
	use_ok( 'JQuery::Taconite' );
	use_ok( 'JQuery::Treeview' );
}

diag( "Testing JQuery $JQuery::VERSION, Perl $], $^X" );
