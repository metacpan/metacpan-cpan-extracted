#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 12;
use KinoSearch1::Store::RAMInvIndex;
use KinoSearch1::Analysis::Tokenizer;
use KinoSearch1::Analysis::PolyAnalyzer;
use KinoSearch1::InvIndexer;
use KinoSearch1::Searcher;
use KinoSearch1::Search::TermQuery;
use KinoSearch1::Index::Term;

my $tokenizer = KinoSearch1::Analysis::Tokenizer->new;
my $polyanalyzer
    = KinoSearch1::Analysis::PolyAnalyzer->new( language => 'en' );

my $invindex = KinoSearch1::Store::RAMInvIndex->new( create => 1 );
my $invindexer = KinoSearch1::InvIndexer->new(
    invindex => $invindex,
    analyzer => $tokenizer,
);

$invindexer->spec_field( name => 'analyzed', );
$invindexer->spec_field(
    name     => 'polyanalyzed',
    analyzer => $polyanalyzer,
);
$invindexer->spec_field(
    name     => 'unanalyzed',
    analyzed => 0,
);
$invindexer->spec_field(
    name     => 'unpolyanalyzed',
    analyzed => 0,
    analyzer => $polyanalyzer,
);
$invindexer->spec_field(
    name    => 'unindexed_but_analyzed',
    indexed => 0,
);
$invindexer->spec_field(
    name     => 'unanalyzed_unindexed',
    analyzed => 0,
    indexed  => 0,
);

sub add_a_doc {
    my $field_name = shift;
    my $doc        = $invindexer->new_doc;
    $doc->set_value( $field_name => 'United States' );
    $invindexer->add_doc($doc);
}

add_a_doc($_) for qw(
    analyzed
    polyanalyzed
    unanalyzed
    unpolyanalyzed
    unindexed_but_analyzed
    unanalyzed_unindexed
);

$invindexer->finish;

sub check {
    my ( $field_name, $query_text, $expected_num_hits ) = @_;

    my $query = KinoSearch1::Search::TermQuery->new(
        term => KinoSearch1::Index::Term->new( $field_name, $query_text ), );

    my $searcher = KinoSearch1::Searcher->new(
        invindex => $invindex,
        analyzer => $tokenizer,    # doesn't matter - no QueryParser
    );

    my $hits = $searcher->search( query => $query );

    is( $hits->total_hits, $expected_num_hits,
        "$field_name correct num hits " );

    # don't check the contents of the hit if there aren't any
    return unless $expected_num_hits;

    my $hit = $hits->fetch_hit_hashref;
    is( $hit->{$field_name},
        'United States',
        "$field_name correct doc returned"
    );
}

check( 'analyzed',               'States',        1 );
check( 'polyanalyzed',           'state',         1 );
check( 'unanalyzed',             'United States', 1 );
check( 'unpolyanalyzed',         'United States', 1 );
check( 'unindexed_but_analyzed', 'state',         0 );
check( 'unindexed_but_analyzed', 'United States', 0 );
check( 'unanalyzed_unindexed',   'state',         0 );
check( 'unanalyzed_unindexed',   'United States', 0 );
