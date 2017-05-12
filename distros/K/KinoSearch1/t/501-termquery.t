#!/usr/bin/perl

use lib 'buildlib';
use Test::More tests => 7;

BEGIN {
    use_ok('KinoSearch1::Search::TermQuery');
    use_ok('KinoSearch1::Index::Term');
    use_ok('KinoSearch1::Searcher');
}

use KinoSearch1::Test::TestUtils qw( create_index );

my $invindex = create_index( 'a', 'b', 'c c c d', 'c d', 'd' .. 'z', );

my $term = KinoSearch1::Index::Term->new( 'content', 'c' );
my $term_query = KinoSearch1::Search::TermQuery->new( term => $term );
my $searcher = KinoSearch1::Searcher->new( invindex => $invindex );

my $hits = $searcher->search( query => $term_query );
$hits->seek( 0, 50 );
is( $hits->total_hits, 2, "correct number of hits returned" );

my $hashref = $hits->fetch_hit_hashref;
is( $hashref->{content}, 'c c c d', "most relevant doc is highest" );

$hashref = $hits->fetch_hit_hashref;
is( $hashref->{content}, 'c d', "second most relevant" );

$hits->seek( 1, 50 );
$hashref = $hits->fetch_hit_hashref;
is( $hashref->{content}, 'c d', "fresh seek" );
