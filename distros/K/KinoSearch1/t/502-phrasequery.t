#!/usr/bin/perl

use lib 'buildlib';
use Test::More tests => 5;

BEGIN { use_ok('KinoSearch1::Search::PhraseQuery') }

use KinoSearch1::Test::TestUtils qw( create_index );
use KinoSearch1::Index::Term;
use KinoSearch1::Searcher;

my $best_match = 'x a b c d a b c d';

my @docs = (
    1 .. 20,
    'a b c a b c a b c d',
    'a b c d x x a',
    'a c b d', 'a x x x b x x x c x x x x x x d x',
    $best_match, 'a' .. 'z',
);

my $invindex = create_index(@docs);
my $searcher = KinoSearch1::Searcher->new( invindex => $invindex );

my $phrase_query = KinoSearch1::Search::PhraseQuery->new( slop => 0 );
for (qw( a b c d )) {
    my $term = KinoSearch1::Index::Term->new( 'content', $_ );
    $phrase_query->add_term($term);
}

my $hits = $searcher->search( query => $phrase_query );
$hits->seek( 0, 50 );
is( $hits->total_hits, 3, "correct number of hits" );
my $first_hit = $hits->fetch_hit_hashref;
is( $first_hit->{content}, $best_match, 'best match appears first' );

my $second_hit = $hits->fetch_hit_hashref;
ok( $first_hit->{score} > $second_hit->{score},
    "best match scores higher: $first_hit->{score} > $second_hit->{score}" );

$phrase_query = KinoSearch1::Search::PhraseQuery->new( slop => 0 );
for (qw( c a )) {
    my $term = KinoSearch1::Index::Term->new( 'content', $_ );
    $phrase_query->add_term($term);
}
$hits = $searcher->search( query => $phrase_query );
is( $hits->total_hits, 1, 'avoid underflow when subtracting offset' );

