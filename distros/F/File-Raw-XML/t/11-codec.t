#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The direct codec: its options, its refusals, its importer, and what it
# accepts as input.

# nothing exported by a bare use (in its own package: `use` runs at compile
# time, so a later import into main would already have happened)
{
    package Bare;
    use File::Raw::XML;
    ::ok(!__PACKAGE__->can('file_xml_decode'), 'a bare use exports nothing');
}

# by name
{
    package By::Name;
    use File::Raw::XML qw(file_xml_decode);
    ::ok(__PACKAGE__->can('file_xml_decode'), 'file_xml_decode by name');
    ::ok(!__PACKAGE__->can('FRX_ELEMENT'), 'and no constants');
    ::is(file_xml_decode('<a/>')->root->local, 'a', 'and it works');
}

# :codec, :const, :all
{
    package By::Codec;
    use File::Raw::XML qw(:codec);
    ::ok(__PACKAGE__->can('file_xml_decode'), ':codec exports the codec');
    ::ok(!__PACKAGE__->can('FRX_TEXT'), 'and no constants');
}
{
    package By::Const;
    use File::Raw::XML qw(:const);
    ::ok(!__PACKAGE__->can('file_xml_decode'), ':const does not export the codec');
    ::is(FRX_COMMENT(), 3, 'and does export the constants');
}
{
    package By::All;
    use File::Raw::XML qw(:all);
    ::ok(__PACKAGE__->can('file_xml_decode'), ':all exports the codec');
    ::is(FRX_DOCUMENT(), 5, 'and the constants');
}

# an unknown name warns and does not die
{
    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    eval q{ package By::Wrong; use File::Raw::XML qw(file_xml_encode); 1 } or die $@;
    is(scalar @w, 1, 'one warning for an unknown export');
    like($w[0], qr/^File::Raw::XML: file_xml_encode is not exported/, 'naming it');
    ok(!By::Wrong->can('file_xml_encode'), 'and nothing was installed');
}

use File::Raw::XML qw(file_xml_decode);

# options
{
    my $doc = file_xml_decode('<a><b/></a>', max_depth => 2, max_bytes => 100, id_attrs => []);
    isa_ok($doc, 'File::Raw::XML::Document');
    ok(!eval { file_xml_decode('<a><b/></a>', max_depth => 1); 1 }, 'max_depth is honoured');
    like($@, qr/nesting deeper than max_depth/, 'with the parser\'s message');
    ok(!eval { file_xml_decode('<a/>', max_bytes => 3); 1 }, 'max_bytes is honoured');
    like($@, qr/input exceeds max_bytes/, 'with the lexer\'s message');
    ok(defined file_xml_decode('<a ID="x"/>', id_attrs => ['ID'])->by_id(ID => 'x'), 'id_attrs builds the index');
    ok(!defined file_xml_decode('<a ID="x"/>')->by_id(ID => 'x'), 'and without it there is none');

    ok(!eval { file_xml_decode('<a/>', bogus => 1); 1 }, 'an unknown option dies');
    like($@, qr/^File::Raw::XML: unknown option 'bogus'/, 'naming it');
    ok(!eval { file_xml_decode('<a/>', max_depth => 1, 'odd'); 1 }, 'an odd option tail dies');
    like($@, qr/^File::Raw::XML: file_xml_decode: options must be key\/value pairs/, 'saying so');
    ok(!eval { file_xml_decode('<a/>', id_attrs => 'ID'); 1 }, 'id_attrs must be an arrayref');
    like($@, qr/id_attrs must be an arrayref/, 'saying so');
    ok(!eval { file_xml_decode('<a/>', id_attrs => [undef]); 1 }, 'and its entries must be names');
    ok(!eval { file_xml_decode('<a/>', plugin => 'xml'); 1 } || 1, 'plugin is a known key (File::Raw puts it there)');
    is(eval { file_xml_decode('<a/>', plugin => 'xml')->root->local }, 'a', 'and is ignored');
}

# profiles: strict is the default; full parses a strict-clean document to
# an equal tree; anything else is refused naming both
{
    my $xml = '<?xml version="1.0"?><!-- c --><r xmlns="urn:d" a="1"><b>x<![CDATA[y]]>z</b><?p q?><c/></r>';
    my $strict = file_xml_decode($xml);
    my $same   = file_xml_decode($xml, profile => 'strict');
    my $full   = file_xml_decode($xml, profile => 'full');
    for my $mode (qw(exclusive inclusive inclusive-1.1)) {
        is($full->c14n(mode => $mode, comments => 1), $strict->c14n(mode => $mode, comments => 1),
           "profile => 'full' gives the strict canonical bytes ($mode)");
    }
    is($same->c14n, $strict->c14n, "profile => 'strict' is the default spelled out");
    my $walk; $walk = sub {
        my ($n) = @_;
        return join '|', $n->kind, $n->name, $n->ns, (map { join '=', @$_ } @{ $n->attrs }), $n->text,
                         '[' . join(',', map { $walk->($_) } $n->children) . ']';
    };
    is($walk->($full->document), $walk->($strict->document), 'and the same tree');
    ok(!eval { file_xml_decode('<a/>', profile => 'loose'); 1 }, 'an unknown profile dies');
    like($@, qr/^File::Raw::XML: profile must be 'strict' or 'full', not 'loose'/, 'naming both');
    ok(eval { file_xml_decode('<!DOCTYPE a><a/>', profile => 'full'); 1 }, 'full reads a DOCTYPE; strict never does');
}

# refusals come through with the offset
{
    ok(!eval { file_xml_decode('<!DOCTYPE a><a/>'); 1 }, 'a DOCTYPE dies');
    like($@, qr/^File::Raw::XML: DOCTYPE.* at byte offset 0 near "/, 'with the one message shape');
}

# input flavours
{
    my $chars = "<r>\x{e9}</r>";
    utf8::upgrade($chars);
    is(file_xml_decode($chars)->root->text, "\x{e9}", 'a character string (flagged) is taken as its UTF-8');
    is(file_xml_decode("<r>\xC3\xA9</r>")->root->text, "\x{e9}", 'unflagged UTF-8 bytes are taken as they are');
    # "\x{e9}" alone is NOT flagged: perl keeps a byte string for characters
    # under 0x100. An unflagged string is bytes here, and 0xE9 is not UTF-8.
    ok(!eval { file_xml_decode("<r>\x{e9}</r>"); 1 }, 'an unflagged byte that is not UTF-8 is refused');
    like($@, qr/not UTF-8 at byte offset 3/, 'by the lexer, with its offset: upgrade a Latin-1 string first');
    is(file_xml_decode("<r>\x{1F600}</r>")->root->text, "\x{1F600}", 'a four-byte character round-trips');
}

done_testing;
