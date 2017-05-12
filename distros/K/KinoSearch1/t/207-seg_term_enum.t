use strict;
use warnings;

use Test::More tests => 9;

BEGIN {
    use_ok('KinoSearch1::Store::RAMInvIndex');
    use_ok('KinoSearch1::InvIndexer');
    use_ok('KinoSearch1::Index::SegTermEnum');
    use_ok('KinoSearch1::Index::CompoundFileReader');
    use_ok('KinoSearch1::Index::FieldInfos');
}

my $invindex   = KinoSearch1::Store::RAMInvIndex->new;
my $invindexer = KinoSearch1::InvIndexer->new(
    invindex => $invindex,
    create   => 1,
);
$invindexer->spec_field( name => 'a' );
$invindexer->spec_field( name => 'b' );
$invindexer->spec_field( name => 'c' );

my @animals = qw( cat dog tick );
for my $animal (@animals) {
    my $doc = $invindexer->new_doc;
    $doc->set_value( $_ => $animal ) for qw( a b c );
    $invindexer->add_doc($doc);
}
$invindexer->finish;

my $cfs_reader = KinoSearch1::Index::CompoundFileReader->new(
    invindex => $invindex,
    seg_name => '_1',
);
my $finfos = KinoSearch1::Index::FieldInfos->new;
$finfos->read_infos( $cfs_reader->open_instream('_1.fnm') );

my $enum = KinoSearch1::Index::SegTermEnum->new(
    finfos   => $finfos,
    instream => $cfs_reader->open_instream('_1.tis'),
);
my @fields;
my @texts;
my ( $pointer, $position, $termstring, $tinfo );
while ( $enum->next ) {
    my $ts = $enum->get_termstring;
    my $term = KinoSearch1::Index::Term->new_from_string( $ts, $finfos );
    push @fields, $term->get_field;
    push @texts,  $term->get_text;
    if ( $term->get_text eq 'tick' and $term->get_field eq 'b' ) {
        $pointer    = $enum->_get_instream->tell;
        $position   = $enum->_get_position;
        $termstring = $enum->get_termstring;
        $tinfo      = $enum->get_term_info;
    }
}
is_deeply( \@fields, [qw( a a a b b b c c c )], "correct fields" );
my @correct_texts = (@animals) x 3;
is_deeply( \@texts, \@correct_texts, "correct terms" );

$enum->seek( $pointer, $position, $termstring, $tinfo );
$enum->next;
my $ts = $enum->get_termstring;
my $term = KinoSearch1::Index::Term->new_from_string( $ts, $finfos );
is( $term->get_text,  'cat', "enum seeks to correct term (ptr)" );
is( $term->get_field, 'c',   "enum seeks to correct term (field)" );

