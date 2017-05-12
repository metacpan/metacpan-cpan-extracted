#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'List::Categorize::Multi' );
}

diag( "Testing List::Categorize::Multi $List::Categorize::Multi::VERSION, Perl $], $^X" );
