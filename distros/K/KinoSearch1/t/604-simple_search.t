#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 12;

use KinoSearch1::Searcher;
use KinoSearch1::InvIndexer;
use KinoSearch1::Store::RAMInvIndex;
use KinoSearch1::Analysis::Tokenizer;
use KinoSearch1::QueryParser::QueryParser;

my $tokenizer  = KinoSearch1::Analysis::Tokenizer->new;
my $invindex   = KinoSearch1::Store::RAMInvIndex->new( create => 1 );
my $invindexer = KinoSearch1::InvIndexer->new(
    analyzer => $tokenizer,
    invindex => $invindex,
);

$invindexer->spec_field( name => 'title' );
$invindexer->spec_field( name => 'body' );

my %docs = (
    'a' => 'foo',
    'b' => 'bar',
);

while ( my ( $title, $body ) = each %docs ) {
    my $doc = $invindexer->new_doc;
    $doc->set_value( title => $title );
    $doc->set_value( body  => $body );
    $invindexer->add_doc($doc);
}
$invindexer->finish;

my $searcher = KinoSearch1::Searcher->new(
    analyzer => $tokenizer,
    invindex => $invindex,
);
my $or_parser = KinoSearch1::QueryParser::QueryParser->new(
    analyzer => $tokenizer,
    fields   => [ 'title', 'body', ],
);
my $and_parser = KinoSearch1::QueryParser::QueryParser->new(
    analyzer       => $tokenizer,
    fields         => [ 'title', 'body', ],
    default_boolop => 'AND',
);

sub test_qstring {
    my ( $qstring, $expected, $message ) = @_;

    my $hits = $searcher->search( query => $qstring );
    is( $hits->total_hits, $expected, $message );

    my $query = $or_parser->parse($qstring);
    $hits = $searcher->search( query => $query );
    is( $hits->total_hits, $expected, "OR: $message" );

    $query = $and_parser->parse($qstring);
    $hits = $searcher->search( query => $query );
    is( $hits->total_hits, $expected, "AND: $message" );
}

test_qstring( 'a foo', 1, "simple match across multiple fields" );
test_qstring( 'a -foo', 0,
    "match of negated term on any field should exclude document" );
test_qstring(
    'a +foo',
    1,
    "failure to match of required term on a field "
        . "should not exclude doc if another field matches."
);
test_qstring( '+a +foo', 1,
    "required terms spread across disparate fields should match" );

