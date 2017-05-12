#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MasonX::Resolver::WidgetFactory' );
}

diag( "Testing MasonX::Resolver::WidgetFactory $MasonX::Resolver::WidgetFactory::VERSION, Perl $], $^X" );
