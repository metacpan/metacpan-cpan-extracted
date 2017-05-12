use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    use_ok('KinoSearch1::Index::SegTermDocs');
    use_ok('KinoSearch1::Index::MultiTermDocs');
    use_ok('KinoSearch1::Index::IndexReader');
    use_ok('KinoSearch1::InvIndexer');
    use_ok('KinoSearch1::Analysis::Tokenizer');
    use_ok('KinoSearch1::Store::RAMInvIndex');
}

my $invindex  = KinoSearch1::Store::RAMInvIndex->new();
my $tokenizer = KinoSearch1::Analysis::Tokenizer->new;
my $id        = 0;
for my $iter ( 1 .. 4 ) {
    my $invindexer = KinoSearch1::InvIndexer->new(
        create => $iter == 1 ? 1 : 0,
        invindex => $invindex,
        analyzer => $tokenizer,
    );
    $invindexer->spec_field( name => 'content' );
    $invindexer->spec_field( name => 'id' );

    for my $letter ( 'a' .. 'y' ) {
        my $doc     = $invindexer->new_doc;
        my $content = ( "$letter " x $iter ) . 'z';
        $doc->set_value( content => $content );
        $doc->set_value( id      => $id++ );
        $invindexer->add_doc($doc);
    }
    $invindexer->finish;
}

my $reader = KinoSearch1::Index::IndexReader->new( invindex => $invindex );

my $term = KinoSearch1::Index::Term->new( 'content', 'c' );
my $term_docs = $reader->term_docs($term);
my ( $docs, $freqs, $prox ) = ( '', '', '' );
my ( $d, $f );
while ( $term_docs->bulk_read( $d, $f, 1024 ) ) {
    $docs  .= $d;
    $freqs .= $f;
}
my @doc_nums = unpack( 'I*', $docs );
is_deeply( \@doc_nums, [ 2, 27, 52, 77 ], "correct doc_nums" );

my @freq_nums = unpack( 'I*', $freqs );
is_deeply( \@freq_nums, [ 1, 2, 3, 4 ], "correct freqs" );

$term_docs->set_read_positions(1);
$term_docs->seek($term);
$prox = '';
$prox .= $term_docs->get_positions while $term_docs->next;
my @prox_nums = unpack( 'I*', $prox );
is_deeply(
    \@prox_nums,
    [ 0, 0, 1, 0, 1, 2, 0, 1, 2, 3 ],
    "correct positions"
);

my $invindexer = KinoSearch1::InvIndexer->new(
    invindex => $invindex,
    analyzer => $tokenizer,
);
$invindexer->delete_docs_by_term( KinoSearch1::Index::Term->new( id => 52 ) );
$invindexer->finish;
$reader    = KinoSearch1::Index::IndexReader->new( invindex => $invindex );
$term_docs = $reader->term_docs($term);
@doc_nums  = ();
push @doc_nums, $term_docs->get_doc, while $term_docs->next;
is_deeply( \@doc_nums, [ 2, 27, 77 ], "deletions handled properly" );
