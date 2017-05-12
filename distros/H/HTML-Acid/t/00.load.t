use Test::More tests => 3;

BEGIN {
use_ok( 'HTML::Acid' );
use_ok( 'HTML::Acid::Buffer' );
use_ok( 'Data::FormValidator::Filters::HTML::Acid' );
}

diag( "Testing HTML::Acid $HTML::Acid::VERSION" );
