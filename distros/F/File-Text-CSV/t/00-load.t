#! perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::Text::CSV' );
}

diag( "Testing File::Text::CSV $File::Text::CSV::VERSION, Perl $], $^X" );
