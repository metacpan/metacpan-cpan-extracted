use utf8;
use warnings;
use strict;
use Test::More;
use Test::Exception;

use Archive::Zip;
use Document::OOXML;
use FindBin;
use Path::Tiny;

my @zip_errors;
Archive::Zip::setErrorHandler(sub { push @zip_errors, $_[0] });

my $doc_dir = path($FindBin::Bin, '..', 't', 'resources');

{
    my $filename = path($doc_dir, 'basic-strict.docx')->stringify;
    my $doc = Document::OOXML->read_document($filename);

    isa_ok($doc, 'Document::OOXML::Document', 'Parsed document');
    isa_ok($doc, 'Document::OOXML::Document::Wordprocessor', 'Parsed document');

    can_ok(
        $doc,
        qw(
            remove_spellcheck_markers
            merge_runs
            find_text_nodes
            replace_text
        )
    );

    is($doc->is_strict, 1, "This is a document in 'strict' mode");
    is($doc->filename, $filename, "Source filename stored correctly");
    isa_ok($doc->content_types, 'Document::OOXML::ContentTypes', 'content_types');

    my $doc_part = $doc->document_part;
    isa_ok($doc_part, 'Document::OOXML::Part::WordprocessingML', 'Document part');

    my $tmp = Path::Tiny->tempfile;
    $doc->save_to_file("$tmp");

    my $doc2 = Document::OOXML->read_document("$tmp");
    isa_ok($doc2, 'Document::OOXML::Document', 'Parsed document');
    isa_ok($doc2, 'Document::OOXML::Document::Wordprocessor', 'Parsed document');

    is_deeply(
        [ sort $doc2->source->memberNames() ],
        [ sort
            '[Content_Types].xml',
            '_rels/.rels',
            'word/_rels/document.xml.rels',
            'word/document.xml',
            'word/theme/theme1.xml',
            'word/settings.xml',
            'word/fontTable.xml',
            'word/webSettings.xml',
            'docProps/app.xml',
            'docProps/core.xml',
            'word/styles.xml'
        ],
        'Saved document contains all expected parts',
    );

    is(
        $doc->document_part->xml->toString,
        $doc2->document_part->xml->toString,
        'Unchanged document is unchanged'
    );
}

{
    my $filename = path($doc_dir, 'basic-regular.docx')->stringify;
    my $doc = Document::OOXML->read_document($filename);

    isa_ok($doc, 'Document::OOXML::Document', 'Parsed document');
    isa_ok($doc, 'Document::OOXML::Document::Wordprocessor', 'Parsed document');

    is($doc->is_strict, 0, "This is NOT a document in 'strict' mode");
    is($doc->filename, $filename, "Source filename stored correctly");
    isa_ok($doc->content_types, 'Document::OOXML::ContentTypes', 'content_types');

    my $doc_part = $doc->document_part;
    isa_ok($doc_part, 'Document::OOXML::Part::WordprocessingML', 'Document part');
}

throws_ok(
    sub {
        Document::OOXML->read_document(
            path($doc_dir, 'not-even-zip.txt')->stringify
        );
    },
    qr{Cannot read: },
    'Opening a .txt file leads to an error from the ZIP library',
);

throws_ok(
    sub {
        Document::OOXML->read_document(
            path($doc_dir, 'not-ooxml.odt')->stringify
        );
    },
    qr{No member named '/\[Content_Types\]\.xml'\. Is it OOXML\?},
    'Opening a non-OOXML file throws an exception'
);

done_testing();
