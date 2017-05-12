#!/usr/bin/perl

use Test::More tests => 5;

BEGIN {
    use_ok('KinoSearch1::Search::Similarity');
}

use KinoSearch1::Store::RAMInvIndex;
use KinoSearch1::Analysis::Tokenizer;
use KinoSearch1::InvIndexer;
use KinoSearch1::Searcher;

my $sim = KinoSearch1::Search::Similarity->new;

my @bytes = map { pack( 'C', $_ ) } ( 100, 110, 120, 130, 140 );
my @floats = ( 0.015625, 0.09375, 0.5, 3.0, 16.0 );
my @transformed = map { $sim->decode_norm($_) } @bytes;
is_deeply( \@floats, \@transformed,
    "decode_norm more or less matches Java Lucene behavior" );

@bytes       = map { pack( 'C', $_ ) } 0 .. 255;
@floats      = map { $sim->decode_norm($_) } @bytes;
@transformed = map { $sim->encode_norm($_) } @floats;
is_deeply( \@transformed, \@bytes,
    "encode_norm and decode_norm are complementary" );

my $norm_decoder = $sim->get_norm_decoder;
@transformed = ();
for ( 0 .. 255 ) {
    push @transformed,
        unpack( 'f', bytes::substr( $norm_decoder, $_ * 4, 4 ) );
}
is_deeply( \@transformed, \@floats,
    "using the norm_decoder produces desired results" );

my $invindex   = KinoSearch1::Store::RAMInvIndex->new( create => 1 );
my $tokenizer  = KinoSearch1::Analysis::Tokenizer->new;
my $invindexer = KinoSearch1::InvIndexer->new(
    analyzer => $tokenizer,
    invindex => $invindex,
);
$invindexer->spec_field( name => 'body' );
$invindexer->spec_field(
    name  => 'title',
    boost => 2,
);
my $title_sim = KinoSearch1::Search::TitleSimilarity->new;
$invindexer->set_similarity( title => $title_sim );

my %source_docs = (
    'spam spam spam spam' => 'a load of spam',
    'not spam'            => 'not spam not even close to spam',
);
while ( my ( $title, $body ) = each %source_docs ) {
    my $doc = $invindexer->new_doc;
    $doc->set_value( title => $title );
    $doc->set_value( body  => $body );
    $invindexer->add_doc($doc);
}
$invindexer->finish;
undef $invindexer;

my $searcher = KinoSearch1::Searcher->new(
    invindex => $invindex,
    analyzer => $tokenizer,
);
$searcher->set_similarity( title => $title_sim );

my $hits = $searcher->search( query => 'spam' );

is( $hits->fetch_hit_hashref->{'title'},
    'not spam', "TitleSimilarity works well on title fields" );
