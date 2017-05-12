#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'LucyX::Search::WildcardQuery' );
}

diag( "Testing LucyX::Search::WildcardQuery $LucyX::Search::WildcardQuery::VERSION, Perl $], $^X" );
