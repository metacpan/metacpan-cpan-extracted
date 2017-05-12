#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'LucyX::Search::AnyTermQuery' );
}

diag( "Testing LucyX::Search::AnyTermQuery $LucyX::Search::AnyTermQuery::VERSION, Perl $], $^X" );
