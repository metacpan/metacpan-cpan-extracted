use strict;
use warnings;

use lib 'buildlib';
use Test::More tests => 7;

BEGIN {
    use_ok('KinoSearch1::Index::SegTermDocs');
    use_ok('KinoSearch1::Index::IndexReader');
}

use KinoSearch1::Test::TestUtils qw( create_index );

my $invindex = create_index( qw( a b c ), 'c c d' );
my $reader = KinoSearch1::Index::IndexReader->new( invindex => $invindex );

my $term = KinoSearch1::Index::Term->new( 'content', 'c' );

my $term_docs = $reader->term_docs($term);

my ( $docs, $freqs, $prox );
$term_docs->bulk_read( $docs, $freqs, 1024 );

my @doc_nums = unpack( 'I*', $docs );
is_deeply( \@doc_nums, [ 2, 3 ], "correct doc_nums" );

my @freq_nums = unpack( 'I*', $freqs );
is_deeply( \@freq_nums, [ 1, 2 ], "correct freqs" );

$term_docs->set_read_positions(1);
$term_docs->seek($term);
$prox = '';
$prox .= $term_docs->get_positions while $term_docs->next;
my @prox_nums = unpack( 'I*', $prox );
is_deeply( \@prox_nums, [ 0, 0, 1 ], "correct positions" );

$term_docs->_get_deldocs()->set(2);
$term_docs->seek($term);

$term_docs->bulk_read( $docs, $freqs, 1024 );
@doc_nums = unpack( 'I*', $docs );
is_deeply( \@doc_nums, [3], "deletions are honored" );

my @documents = ( qw( c ), 'c c d', );
push @documents, "$_ c" for 0 .. 200;

$invindex = create_index(@documents);

$reader = KinoSearch1::Index::IndexReader->new( invindex => $invindex );
$term_docs = $reader->term_docs($term);

$term_docs->bulk_read( $docs, $freqs, 1024 );
@doc_nums = unpack( 'I*', $docs );
is_deeply( \@doc_nums, [ 0 .. 202 ], "large number of doc_nums correct" );
