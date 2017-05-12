#!perl -Tw

use Test::More tests => 2;

BEGIN {
    use_ok( 'HTML::Lint' );
}

BEGIN {
    use_ok( 'Test::HTML::Lint' );
}

diag( "Testing HTML::Lint $HTML::Lint::VERSION, Perl $], $^X" );
