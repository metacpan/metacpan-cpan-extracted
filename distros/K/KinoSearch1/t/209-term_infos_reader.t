use strict;
use warnings;

use lib 'buildlib';
use Test::More tests => 6;

BEGIN {
    use_ok('KinoSearch1::Index::TermInfosReader');
    use_ok('KinoSearch1::Index::CompoundFileReader');
    use_ok('KinoSearch1::Index::FieldInfos');
    use_ok('KinoSearch1::Index::Term');
}

use KinoSearch1::Test::TestUtils qw( create_index );

my @docs;
my @chars = ( 'a' .. 'z' );
for ( 0 .. 1000 ) {
    my $content = '';
    for my $num_words ( 0 .. int( rand(20) ) ) {
        for my $num_chars ( 1 .. int( rand(10) ) ) {
            $content .= @chars[ rand(@chars) ];
        }
        $content .= ' ';
    }
    push @docs, "$content\n";
}
my $invindex = create_index(
    ( 1 .. 1000 ),
    ( ("a") x 100 ),
    "Foo",
    @docs,
    "Foo",
    "A MAN",
    "A PLAN",
    "A CANAL",
    "PANAMA"
);

my $comp_file_reader = KinoSearch1::Index::CompoundFileReader->new(
    invindex => $invindex,
    seg_name => '_1',
);
my $finfos = KinoSearch1::Index::FieldInfos->new;
$finfos->read_infos( $comp_file_reader->open_instream('_1.fnm') );

my $tinfos_reader = KinoSearch1::Index::TermInfosReader->new(
    invindex => $comp_file_reader,
    seg_name => '_1',
    finfos   => $finfos,
);

my $term = KinoSearch1::Index::Term->new( 'content', 'A' );
my $tinfo = $tinfos_reader->fetch_term_info($term);

is( $tinfo->get_doc_freq, 3, "correct retrieval #1" );

$term = KinoSearch1::Index::Term->new( 'content', "Foo" );
$tinfo = $tinfos_reader->fetch_term_info($term);

is( $tinfo->get_doc_freq, 2, "correct retrieval #2" );
