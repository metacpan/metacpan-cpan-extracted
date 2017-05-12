use strict;
use warnings;

use Test::More tests => 3;
use Scalar::Util qw( dualvar );

BEGIN { use_ok('KinoSearch1::Search::HitQueue') }

my $hq = KinoSearch1::Search::HitQueue->new( max_size => 10 );

my @docs_and_scores = (
    [ 1.0, 0 ],
    [ 0.1, 5 ],
    [ 0.1, 10 ],
    [ 0.9, 1000 ],
    [ 1.0, 3000 ],
    [ 1.0, 2000 ],
);

my @scoredocs
    = map { dualvar( $_->[0], pack( 'N', $_->[1] ) ) } @docs_and_scores;

my @correct_order = sort { $b <=> $a or $a cmp $b } @scoredocs;
my @correct_docs = map { unpack( 'N', "$_" ) } @correct_order;
my @correct_scores = map { 0 + $_ } @correct_order;

my $hit_docs;
$hq->insert($_) for @scoredocs;
$hit_docs = $hq->hits;

my @scores = map { $_->get_score } @$hit_docs;
is_deeply( \@scores, \@correct_scores, "rank by scores first" );

my @doc_nums = map { $_->get_id } @$hit_docs;
is_deeply( \@doc_nums, \@correct_docs, "rank by doc_num after score" );
