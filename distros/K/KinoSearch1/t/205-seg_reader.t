#!/usr/bin/perl
use strict;
use warnings;

use lib 'buildlib';
use Test::More tests => 8;

BEGIN {
    use_ok('KinoSearch1::Index::IndexReader');
    use_ok('KinoSearch1::Index::Term');
}

use KinoSearch1::Test::TestUtils qw( create_index );

my $invindex = create_index(
    "What's he building in there?",
    "What's he building in there?",
    "We have a right to know."
);

my $reader = KinoSearch1::Index::IndexReader->new( invindex => $invindex );

isa_ok(
    $reader,
    'KinoSearch1::Index::SegReader',
    "single segment indexes cause new to return a SegReader"
);

isa_ok( $reader->norms_reader('content'), 'KinoSearch1::Index::NormsReader' );
ok( !$reader->has_deletions, "has_deletions returns false if no deletions" );
is( $reader->max_doc, 3, "max_doc returns correct number" );

my $term = KinoSearch1::Index::Term->new( 'content', 'building' );
my $enum = $reader->terms($term);
isa_ok(
    $enum,
    'KinoSearch1::Index::SegTermEnum',
    "terms returns a SegTermEnum"
);
my $tinfo = $enum->get_term_info;
is( $tinfo->get_doc_freq, 2, "correct place in enum" );

