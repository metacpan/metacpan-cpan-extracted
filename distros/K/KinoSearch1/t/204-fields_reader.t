use strict;
use warnings;

use Test::More tests => 22;

BEGIN { use_ok('KinoSearch1::InvIndexer') }
BEGIN { use_ok('KinoSearch1::Store::RAMInvIndex') }
BEGIN { use_ok('KinoSearch1::Index::FieldsReader') }
BEGIN { use_ok('KinoSearch1::Index::CompoundFileReader') }
BEGIN { use_ok('KinoSearch1::Index::FieldInfos') }

my $invindex   = KinoSearch1::Store::RAMInvIndex->new;
my $invindexer = KinoSearch1::InvIndexer->new(
    invindex => $invindex,
    create   => 1,
);

# This valid UTF-8 string includes skull and crossbones, null byte -- however,
# it is not flagged as UTF-8.
my $bin_val = my $val = "a b c \xe2\x98\xA0 \0a";

my %field_specs = (
    text => {
        indexed    => 1,
        binary     => 0,
        compressed => 0,
        value      => $val,
    },
    text_comp => {
        indexed    => 1,
        binary     => 0,
        compressed => 1,
        value      => $val,
    },
    bin => {
        indexed    => 0,
        binary     => 1,
        compressed => 0,
        value      => $bin_val,
    },
    bin_comp => {
        indexed    => 0,
        binary     => 1,
        compressed => 1,
        value      => $bin_val,
    },
);
while ( my ( $name, $spec ) = each %field_specs ) {
    $invindexer->spec_field(
        name       => $name,
        indexed    => $spec->{indexed},
        binary     => $spec->{binary},
        compressed => $spec->{compressed},
    );
}

my $doc = $invindexer->new_doc;
$doc->set_value( $_ => $field_specs{$_}{value} ) for keys %field_specs;
$invindexer->add_doc($doc);
$invindexer->finish;

my $cfs_reader = KinoSearch1::Index::CompoundFileReader->new(
    invindex => $invindex,
    seg_name => '_1',
);

my $finfos = KinoSearch1::Index::FieldInfos->new;
$finfos->read_infos( $cfs_reader->open_instream('_1.fnm') );

my $fields_reader = KinoSearch1::Index::FieldsReader->new(
    finfos        => $finfos,
    fdata_stream  => $cfs_reader->open_instream('_1.fdt'),
    findex_stream => $cfs_reader->open_instream('_1.fdx'),
);

$doc = $fields_reader->fetch_doc(0);
isa_ok( $doc, 'KinoSearch1::Document::Doc' );

#while ( my ( $name, $spec ) = each %field_specs ) {
for my $field ( $doc->get_fields ) {
    my $name = $field->get_name;
    my $spec = $field_specs{$name};
    is( $field->get_indexed, $spec->{indexed}, "correct val for indexed" );
    is( $field->get_binary,  $spec->{binary},  "correct val for binary" );
    is( $field->get_compressed, $spec->{compressed},
        "correct val for compressed" );
    is( $field->get_value, $spec->{value}, "correct content" );
}
