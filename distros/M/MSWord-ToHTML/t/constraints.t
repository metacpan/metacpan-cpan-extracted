#!/usr/bin/env perl

use strictures 1;
use Test::Most tests => 113;
use Test::Moose;
use Module::Find;
use Archive::Zip::MemberRead;
use lib 'lib';
use MSWord::ToHTML;
use MSWord::ToHTML::Types::Library qw/:all/;

my @docs  = glob('t/data/*.doc');
my @docxs = glob('t/data/*.docx');

my $converter = MSWord::ToHTML->new;

for my $doc (@docs) {
    my ( $new_doc, $second );
    lives_ok { $new_doc = to_MyFile($doc) } "I can coerce $doc to a MyFile";
    ok( is_MyFile($new_doc), "My new doc isa MyFile" );
    $new_doc = $converter->validate_file($doc);
    ok( is_MyFile( $new_doc->file ), "My new doc has a MyFile" );
    isa_ok( $new_doc->file, "IO::All::File" );
    isa_ok( $new_doc,       "MSWord::ToHTML::Doc" );
    meta_ok($new_doc);
    can_ok( $new_doc, qw/get_html/ );
    $new_doc->get_html;
}

for my $docx (@docxs) {
    my ( $new_docx, $internal_xml_check );
    lives_ok { $new_docx = to_MyFile($docx) }
    "I can coerce $docx to a MyFile";
    ok( is_MyFile($new_docx), "My new doc isa MyFile" );
    $new_docx = $converter->validate_file($docx);
    ok( is_MyFile( $new_docx->file ), "My new docx has a MyFile" );
    isa_ok( $new_docx->file, "IO::All::File" );
    lives_ok {
        $internal_xml_check = Archive::Zip::MemberRead->new(
            Archive::Zip->new(
                $new_docx->file->filepath . $new_docx->file->filename
            ),
            "word/document.xml"
        );
    }
    "I can check for the main xml file in the docx";
    isa_ok( $internal_xml_check, "Archive::Zip::MemberRead" );
    isa_ok( $new_docx,           "MSWord::ToHTML::DocX" );
    meta_ok($new_docx);
    can_ok( $new_docx, qw/get_html/ );
    $new_docx->get_html;
}
