use strict;
use warnings;

use lib 'buildlib';
use Test::More tests => 2;

use KinoSearch1::Search::HitCollector;
use KinoSearch1::Searcher;
use KinoSearch1::Analysis::Tokenizer;
use KinoSearch1::Search::TermQuery;
use KinoSearch1::Index::Term;

BEGIN { use_ok('KinoSearch1::Search::QueryFilter') }

use KinoSearch1::Test::TestUtils qw( create_index );

my $invindex = create_index( 'a x', 'b x', 'c x', 'a y', 'b y', 'c y' );

my $searcher = KinoSearch1::Searcher->new(
    invindex => $invindex,
    analyzer => KinoSearch1::Analysis::Tokenizer->new,
);

my $only_a_query = KinoSearch1::Search::TermQuery->new(
    term => KinoSearch1::Index::Term->new( 'content', 'a' ), );
my $filter = KinoSearch1::Search::QueryFilter->new( query => $only_a_query, );

my $hits = $searcher->search(
    query  => 'x y',
    filter => $filter,
);
$hits->seek( 0, 50 );

is( $hits->total_hits, 2, "filtering a query works" );

