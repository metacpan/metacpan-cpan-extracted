use strict;
use warnings;

use lib 'buildlib';
use Test::More tests => 9;

BEGIN {
    use_ok('KinoSearch1::Searcher');
    use_ok('KinoSearch1::Analysis::Tokenizer');
    use_ok('KinoSearch1::Highlight::Highlighter');
}

use KinoSearch1::InvIndexer;
use KinoSearch1::Store::RAMInvIndex;
my $tokenizer  = KinoSearch1::Analysis::Tokenizer->new;
my $invindex   = KinoSearch1::Store::RAMInvIndex->new( create => 1 );
my $invindexer = KinoSearch1::InvIndexer->new(
    invindex => $invindex,
    analyzer => $tokenizer,
);
$invindexer->spec_field( name => 'content' );
$invindexer->spec_field( name => 'alt', boost => 0.1 );

my $string = '1 2 3 4 5 ' x 20;    # 200 characters
$string .= 'a b c d x y z h i j k ';
$string .= '6 7 8 9 0 ' x 20;
my $with_quotes = '"I see," said the blind man.';

for ( $string, $with_quotes ) {
    my $doc = $invindexer->new_doc;
    $doc->set_value( content => $_ );
    $invindexer->add_doc($doc);
}
{
    my $doc = $invindexer->new_doc;
    $doc->set_value( alt => $string . " and extra stuff so it scores lower" );
    $doc->set_value( content => "x but not why or 2ee" );
    $invindexer->add_doc($doc);
}
$invindexer->finish;

my $searcher = KinoSearch1::Searcher->new(
    invindex => $invindex,
    analyzer => $tokenizer,
);
my $highlighter
    = KinoSearch1::Highlight::Highlighter->new( excerpt_field => 'content', );

my $hits = $searcher->search( query => '"x y z" AND b' );
$hits->create_excerpts( highlighter => $highlighter );
$hits->seek( 0, 2 );
my $hit = $hits->fetch_hit_hashref;
like( $hit->{excerpt}, qr/b.*?z/, "excerpt contains all relevant terms" );
like(
    $hit->{excerpt},
    qr#<strong>x y z</strong>#,
    "highlighter tagged the phrase"
);
like( $hit->{excerpt}, qr#<strong>b</strong>#,
    "highlighter tagged the single term" );

like( $hits->fetch_hit_hashref()->{excerpt},
    qr/x/,
    "excerpt field with partial hit doesn't cause highlighter freakout" );

$hits = $searcher->search( query => 'x "x y z" AND b' );
$hits->create_excerpts( highlighter => $highlighter );
$hits->seek( 0, 2 );
like( $hits->fetch_hit_hashref()->{excerpt},
    qr/x y z/,
    "query with same word in both phrase and term doesn't cause freakout" );

$hits = $searcher->search( query => 'blind' );
$hits->create_excerpts( highlighter => $highlighter );
like( $hits->fetch_hit_hashref()->{excerpt},
    qr/quot/, "HTML entity encoded properly" );

