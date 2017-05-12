#!/usr/bin/perl
use strict;
use warnings;

use lib 'buildlib';
use Test::More tests => 4;

BEGIN { use_ok('KinoSearch1::Search::Hits') }
use KinoSearch1::Searcher;
use KinoSearch1::Analysis::Tokenizer;
use KinoSearch1::Test::TestUtils qw( create_index );

my @docs = ( 'a b', 'a a b', 'a a a b', 'x' );
my $invindex = create_index(@docs);

my $searcher = KinoSearch1::Searcher->new(
    invindex => $invindex,
    analyzer => KinoSearch1::Analysis::Tokenizer->new,
);

my $hits = $searcher->search( query => 'a' );
my @ids;
my @retrieved;
while ( my $hit = $hits->fetch_hit ) {
    push @ids, $hit->get_id;
    my $doc = $hit->get_doc;
    push @retrieved, $doc->get_value('content');
}
is_deeply( \@ids, [ 2, 1, 0 ], "get_id()" );
is_deeply(
    \@retrieved,
    [ @docs[ 2, 1, 0 ] ],
    "correct content via fetch_hit() and get_doc()"
);

@retrieved = ();
$hits = $searcher->search( query => 'a' );
while ( my $hashref = $hits->fetch_hit_hashref ) {
    push @retrieved, $hashref->{content};
}
is_deeply(
    \@retrieved,
    [ @docs[ 2, 1, 0 ] ],
    "correct content via fetch_hit_hashref()"
);
