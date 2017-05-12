#!/usr/bin/perl
use strict;
use warnings;

use lib 'buildlib';
use KinoSearch1 qw( kdump );
use Test::More tests => 217;

BEGIN { use_ok('KinoSearch1::QueryParser::QueryParser') }

use KinoSearch1::InvIndexer;
use KinoSearch1::Searcher;
use KinoSearch1::Store::RAMInvIndex;
use KinoSearch1::Analysis::Tokenizer;
use KinoSearch1::Analysis::Stopalizer;
use KinoSearch1::Analysis::PolyAnalyzer;

my $whitespace_tokenizer
    = KinoSearch1::Analysis::Tokenizer->new( token_re => qr/\S+/ );
my $stopalizer
    = KinoSearch1::Analysis::Stopalizer->new( stoplist => { x => 1 } );
my $polyanalyzer = KinoSearch1::Analysis::PolyAnalyzer->new(
    analyzers => [ $whitespace_tokenizer, $stopalizer, ], );

my @docs = ( 'x', 'y', 'z', 'x a', 'x a b', 'x a b c', 'x foo a b c d', );
my $invindex      = KinoSearch1::Store::RAMInvIndex->new( create => 1 );
my $stop_invindex = KinoSearch1::Store::RAMInvIndex->new( create => 1 );
my $invindexer    = KinoSearch1::InvIndexer->new(
    invindex => $invindex,
    analyzer => $whitespace_tokenizer,
);
my $stop_invindexer = KinoSearch1::InvIndexer->new(
    invindex => $stop_invindex,
    analyzer => $polyanalyzer,
);
$invindexer->spec_field( name => 'content' );
$stop_invindexer->spec_field( name => 'content' );

for my $content_string (@docs) {
    my $doc = $invindexer->new_doc;
    $doc->set_value( content => $content_string );
    $invindexer->add_doc($doc);
    $doc = $stop_invindexer->new_doc;
    $doc->set_value( content => $content_string );
    $stop_invindexer->add_doc($doc);
}
$invindexer->finish;
$stop_invindexer->finish;

my $OR_parser = KinoSearch1::QueryParser::QueryParser->new(
    analyzer      => $whitespace_tokenizer,
    default_field => 'content',
);
my $AND_parser = KinoSearch1::QueryParser::QueryParser->new(
    analyzer       => $whitespace_tokenizer,
    default_field  => 'content',
    default_boolop => 'AND',
);

my $OR_stop_parser = KinoSearch1::QueryParser::QueryParser->new(
    analyzer      => $polyanalyzer,
    default_field => 'content',
);
my $AND_stop_parser = KinoSearch1::QueryParser::QueryParser->new(
    analyzer       => $polyanalyzer,
    default_field  => 'content',
    default_boolop => 'AND',
);

my $searcher      = KinoSearch1::Searcher->new( invindex => $invindex );
my $stop_searcher = KinoSearch1::Searcher->new( invindex => $stop_invindex );

my @logical_tests = (

    'b'     => [ 3, 3, 3, 3, ],
    '(a)'   => [ 4, 4, 4, 4, ],
    '"a"'   => [ 4, 4, 4, 4, ],
    '"(a)"' => [ 0, 0, 0, 0, ],
    '("a")' => [ 4, 4, 4, 4, ],

    'a b'     => [ 4, 3, 4, 3, ],
    'a (b)'   => [ 4, 3, 4, 3, ],
    'a "b"'   => [ 4, 3, 4, 3, ],
    'a ("b")' => [ 4, 3, 4, 3, ],
    'a "(b)"' => [ 4, 0, 4, 0, ],

    '(a b)'   => [ 4, 3, 4, 3, ],
    '"a b"'   => [ 3, 3, 3, 3, ],
    '("a b")' => [ 3, 3, 3, 3, ],
    '"(a b)"' => [ 0, 0, 0, 0, ],

    'a b c'     => [ 4, 2, 4, 2, ],
    'a (b c)'   => [ 4, 2, 4, 2, ],
    'a "b c"'   => [ 4, 2, 4, 2, ],
    'a ("b c")' => [ 4, 2, 4, 2, ],
    'a "(b c)"' => [ 4, 0, 4, 0, ],
    '"a b c"'   => [ 2, 2, 2, 2, ],

    '-x'     => [ 0, 0, 0, 0, ],
    'x -c'   => [ 3, 3, 0, 0, ],
    'x "-c"' => [ 5, 0, 0, 0, ],
    'x +c'   => [ 2, 2, 2, 2, ],
    'x "+c"' => [ 5, 0, 0, 0, ],

    '+x +c' => [ 2, 2, 2, 2, ],
    '+x -c' => [ 3, 3, 0, 0, ],
    '-x +c' => [ 0, 0, 2, 2, ],
    '-x -c' => [ 0, 0, 0, 0, ],

    'x y'     => [ 6, 0, 1, 1, ],
    'x a d'   => [ 5, 1, 4, 1, ],
    'x "a d"' => [ 5, 0, 0, 0, ],
    '"x a"'   => [ 3, 3, 3, 3, ],

    'x AND y'     => [ 0, 0, 1, 1, ],
    'x OR y'      => [ 6, 6, 1, 1, ],
    'x AND NOT y' => [ 5, 5, 0, 0, ],

    'x (b OR c)'     => [ 5, 3, 3, 3, ],
    'x AND (b OR c)' => [ 3, 3, 3, 3, ],
    'x OR (b OR c)'  => [ 5, 5, 3, 3, ],
    'x (y OR c)'     => [ 6, 2, 3, 3, ],
    'x AND (y OR c)' => [ 2, 2, 3, 3, ],

    'a AND NOT (b OR "c d")'     => [ 1, 1, 1, 1, ],
    'a AND NOT "a b"'            => [ 1, 1, 1, 1, ],
    'a AND NOT ("a b" OR "c d")' => [ 1, 1, 1, 1, ],

    '+"b c" -d' => [ 1, 1, 1, 1, ],
    '"a b" +d'  => [ 1, 1, 1, 1, ],

    'x AND NOT (b OR (c AND d))' => [ 2, 2, 0, 0, ],

    '-(+notthere)' => [ 0, 0, 0, 0 ],

    'content:b'              => [ 3, 3, 3, 3, ],
    'bogusfield:a'           => [ 0, 0, 0, 0, ],
    'bogusfield:a content:b' => [ 3, 0, 3, 0, ],

    'content:b content:c' => [ 3, 2, 3, 2 ],
    'content:(b c)'       => [ 3, 2, 3, 2 ],
    'bogusfield:(b c)'    => [ 0, 0, 0, 0 ],

);

my $i = 0;
while ( $i < @logical_tests ) {
    my $qstring = $logical_tests[$i];
    $i++;

    my $query = $OR_parser->parse($qstring);
    my $hits = $searcher->search( query => $query );
    $hits->seek( 0, 50 );
    is( $hits->total_hits, $logical_tests[$i][0], "OR:    $qstring" );

    $query = $AND_parser->parse($qstring);
    $hits = $searcher->search( query => $query );
    $hits->seek( 0, 50 );
    is( $hits->total_hits, $logical_tests[$i][1], "AND:   $qstring" );

    $query = $OR_stop_parser->parse($qstring);
    $hits = $stop_searcher->search( query => $query );
    $hits->seek( 0, 50 );
    is( $hits->total_hits, $logical_tests[$i][2], "stoplist-OR:   $qstring" );

    $query = $AND_stop_parser->parse($qstring);
    $hits = $stop_searcher->search( query => $query );
    $hits->seek( 0, 50 );
    is( $hits->total_hits, $logical_tests[$i][3],
        "stoplist-AND:   $qstring" );

    $i++;

    $hits->{searcher} = undef;
    $hits->{reader}   = undef;
    $hits->{weight}   = undef;
    #kdump($query);
    #exit;
}
