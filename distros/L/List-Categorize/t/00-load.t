#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'List::Categorize' );
}

diag( "Testing List::Categorize $List::Categorize::VERSION, Perl $], $^X" );
