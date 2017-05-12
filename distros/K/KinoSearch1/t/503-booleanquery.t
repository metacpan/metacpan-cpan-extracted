#!/usr/bin/perl

use lib 'buildlib';
use Test::More tests => 6;
use File::Spec::Functions qw( catfile );

BEGIN {
    use_ok('KinoSearch1::Search::BooleanQuery');
    use_ok('KinoSearch1::Search::BooleanScorer');
}

use KinoSearch1::Test::TestUtils qw( create_index );

use KinoSearch1::Search::TermQuery;
use KinoSearch1::Index::Term;
use KinoSearch1::Searcher;
use KinoSearch1::Analysis::Tokenizer;

my @docs = ( 'a' .. 'h', 'c c', 'c d e' );
push @docs, ('x') x 90;
push @docs, ('c d x');
my $invindex  = create_index(@docs);
my $tokenizer = KinoSearch1::Analysis::Tokenizer->new;

my $searcher = KinoSearch1::Searcher->new(
    invindex => $invindex,
    analyzer => $tokenizer,
);

my $bool_query = KinoSearch1::Search::BooleanQuery->new;

my $c_query = KinoSearch1::Search::TermQuery->new(
    term => KinoSearch1::Index::Term->new( 'content', 'c' ), );
my $d_query = KinoSearch1::Search::TermQuery->new(
    term => KinoSearch1::Index::Term->new( 'content', 'd' ), );
my $e_query = KinoSearch1::Search::TermQuery->new(
    term => KinoSearch1::Index::Term->new( 'content', 'e' ), );

$bool_query->add_clause(
    query => $c_query,
    occur => 'SHOULD',
);
my $hits = $searcher->search( query => $bool_query );
$hits->seek( 0, 10 );
is( $hits->total_hits, 4, "single clause" );

$bool_query->add_clause(
    query => $d_query,
    occur => 'MUST',
);
$hits = $searcher->search( query => $bool_query );
$hits->seek( 0, 10 );
is( $hits->total_hits, 3, "c +d" );

$bool_query->add_clause(
    query => $e_query,
    occur => 'MUST_NOT',
);
$hits = $searcher->search( query => $bool_query );
$hits->seek( 0, 10 );
is( $hits->total_hits, 2, "c +d -e" );

$bool_query = KinoSearch1::Search::BooleanQuery->new;
$bool_query->add_clause( query => $c_query, occur => 'SHOULD' );
my $sub_query = KinoSearch1::Search::BooleanQuery->new;
$sub_query->add_clause( query => $d_query, occur => 'SHOULD', );
$sub_query->add_clause( query => $e_query, occur => 'SHOULD', );
$bool_query->add_clause( query => $sub_query, occur => 'SHOULD' );

$hits = $searcher->search( query => $bool_query );
$hits->seek( 0, 50 );
is( $hits->total_hits, 6, "nested BooleanQuery" );
