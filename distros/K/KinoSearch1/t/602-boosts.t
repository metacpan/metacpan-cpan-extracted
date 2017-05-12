#!/usr/bin/perl
use strict;
use warnings;

use lib 'buildlib';
use Test::More 'no_plan';

use KinoSearch1::Store::RAMInvIndex;
use KinoSearch1::Searcher;
use KinoSearch1::InvIndexer;
use KinoSearch1::Analysis::Tokenizer;

my $control_invindex = KinoSearch1::Store::RAMInvIndex->new( create => 1 );
my $boosted_fields_invindex_a
    = KinoSearch1::Store::RAMInvIndex->new( create => 1 );
my $boosted_fields_invindex_b
    = KinoSearch1::Store::RAMInvIndex->new( create => 1 );
my $boosted_docs_invindex
    = KinoSearch1::Store::RAMInvIndex->new( create => 1 );
my $analyzer = KinoSearch1::Analysis::Tokenizer->new( token_re => qr/\S+/ );

my $control_invindexer = KinoSearch1::InvIndexer->new(
    invindex => $control_invindex,
    analyzer => $analyzer,

);
my $boosted_fields_invindexer_a = KinoSearch1::InvIndexer->new(
    invindex => $boosted_fields_invindex_a,
    analyzer => $analyzer,
);
my $boosted_fields_invindexer_b = KinoSearch1::InvIndexer->new(
    invindex => $boosted_fields_invindex_b,
    analyzer => $analyzer,
);
my $boosted_docs_invindexer = KinoSearch1::InvIndexer->new(
    invindex => $boosted_docs_invindex,
    analyzer => $analyzer,
);

for ( $control_invindexer, $boosted_fields_invindexer_b,
    $boosted_docs_invindexer )
{
    $_->spec_field( name => 'content' );
    $_->spec_field( name => 'category' );
}

$boosted_fields_invindexer_a->spec_field( name => 'content' );
$boosted_fields_invindexer_a->spec_field(
    name  => 'category',
    boost => 100,
);

my %source_docs = (
    'x'         => '',
    'x a a a a' => 'x a',
    'a b'       => 'x a a',
);

while ( my ( $content, $category ) = each %source_docs ) {
    my $doc = $control_invindexer->new_doc;
    $doc->set_value( content  => $content );
    $doc->set_value( category => $category );
    $control_invindexer->add_doc($doc);

    $doc = $boosted_fields_invindexer_a->new_doc;
    $doc->set_value( content  => $content );
    $doc->set_value( category => $category );
    $boosted_fields_invindexer_a->add_doc($doc);

    $doc = $boosted_fields_invindexer_b->new_doc;
    $doc->set_value( content  => $content );
    $doc->set_value( category => $category );
    $doc->boost_field( content => 5 ) if ( $content =~ 'b' );
    $boosted_fields_invindexer_b->add_doc($doc);

    $doc = $boosted_docs_invindexer->new_doc;
    $doc->set_value( content  => $content );
    $doc->set_value( category => $category );
    $doc->set_boost(5) if ( $content =~ 'b' );
    $boosted_docs_invindexer->add_doc($doc);
}

$control_invindexer->finish;
$boosted_fields_invindexer_a->finish;
$boosted_fields_invindexer_b->finish;
$boosted_docs_invindexer->finish;

my $searcher = KinoSearch1::Searcher->new(
    invindex => $control_invindex,
    analyzer => $analyzer,
);
my $hits = $searcher->search('a');
$hits->seek( 0, 1 );
my $hit = $hits->fetch_hit_hashref;
is( $hit->{content}, "x a a a a", "best doc ranks highest with no boosting" );

$searcher = KinoSearch1::Searcher->new(
    invindex => $boosted_fields_invindex_a,
    analyzer => $analyzer,
);
$hits = $searcher->search('a');
$hits->seek( 0, 3 );
$hit = $hits->fetch_hit_hashref;
is( $hit->{content}, 'a b', "boost from spec_field works" );

$searcher = KinoSearch1::Searcher->new(
    invindex => $boosted_fields_invindex_b,
    analyzer => $analyzer,
);
$hits = $searcher->search('a');
$hits->seek( 0, 1 );
$hit = $hits->fetch_hit_hashref;
is( $hit->{content}, 'a b', "boost from \$doc->boost_field works" );

$searcher = KinoSearch1::Searcher->new(
    invindex => $boosted_docs_invindex,
    analyzer => $analyzer,
);
$hits = $searcher->search('a');
$hits->seek( 0, 1 );
$hit = $hits->fetch_hit_hashref;
is( $hit->{content}, 'a b', "boost from \$doc->set_boost works" );
