#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;
use lib 'buildlib';

BEGIN { use_ok('KinoSearch1::Search::MultiSearcher') }

use KinoSearch1::Searcher;
use KinoSearch1::Analysis::Tokenizer;

use KinoSearch1::Test::TestUtils qw( create_index );
my $invindex_a = create_index( 'x a', 'x b', 'x c' );
my $invindex_b = create_index( 'y b', 'y c', 'y d' );

my $tokenizer = KinoSearch1::Analysis::Tokenizer->new;

my $searcher_a = KinoSearch1::Searcher->new(
    analyzer => $tokenizer,
    invindex => $invindex_a,
);
my $searcher_b = KinoSearch1::Searcher->new(
    analyzer => $tokenizer,
    invindex => $invindex_b,
);

my $multi_searcher = KinoSearch1::Search::MultiSearcher->new(
    searchables => [ $searcher_a, $searcher_b ],
    analyzer    => $tokenizer,
);

my $hits = $multi_searcher->search('a');
is( $hits->total_hits, 1, "Find hit in first searcher" );

$hits = $multi_searcher->search('d');
is( $hits->total_hits, 1, "Find hit in second searcher" );

$hits = $multi_searcher->search('c');
is( $hits->total_hits, 2, "Find hits in both searchers" );
