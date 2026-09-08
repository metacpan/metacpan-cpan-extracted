#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw qw(slurp spew);   # each_line is not importable under that name; called qualified
use File::Raw::XML;

# file_slurp($path, plugin => 'xml'): the same document the codec returns,
# the options through the plugin context, and the phases that are refused.

my $dir = tempdir(CLEANUP => 1);
sub path { "$dir/$_[0]" }
sub write_file {
    my ($name, $bytes) = @_;
    open my $fh, '>:raw', path($name) or die "open: $!";
    print {$fh} $bytes;
    close $fh;
    return path($name);
}

# the plugin is registered
{
    my $f   = write_file('a.xml', '<?xml version="1.0"?><r xmlns="urn:d"><a/></r>');
    my $doc = file_slurp($f, plugin => 'xml');
    isa_ok($doc, 'File::Raw::XML::Document', 'slurp with plugin => xml');
    is($doc->root->local, 'r', 'and the root is right');
    is($doc->root->ns, 'urn:d', 'with its namespace');
    is_deeply([map { $_->local } $doc->root->elements], ['a'], 'and its children');
}

# options arrive through the context
{
    my $f = write_file('deep.xml', '<a><b><c/></b></a>');
    ok(file_slurp($f, plugin => 'xml'), 'the default depth accepts it');
    ok(!eval { file_slurp($f, plugin => 'xml', max_depth => 2); 1 }, 'max_depth through the plugin refuses');
    like($@, qr/nesting deeper than max_depth at byte offset 6/, 'with the parser\'s message and offset');
    ok(!eval { file_slurp($f, plugin => 'xml', max_bytes => 5); 1 }, 'max_bytes through the plugin refuses');

    $f = write_file('ids.xml', '<r><a ID="x"/><b ID="y"/></r>');
    my $doc = file_slurp($f, plugin => 'xml', id_attrs => ['ID']);
    is($doc->by_id(ID => 'y')->local, 'b', 'id_attrs through the plugin builds the index');
    is(file_slurp($f, plugin => 'xml')->by_id(ID => 'y'), undef, 'and without it there is none');

    ok(!eval { file_slurp($f, plugin => 'xml', bogus => 1); 1 }, 'an unknown option refuses');
    like($@, qr/^File::Raw::XML: unknown option 'bogus'/, 'with the same message the codec gives');
    ok(!eval { file_slurp($f, plugin => 'xml', id_attrs => 'ID'); 1 }, 'id_attrs is checked the same way');
}

# refusals keep their offsets
{
    my $f = write_file('doctype.xml', "<!DOCTYPE r>\n<r/>");
    ok(!eval { file_slurp($f, plugin => 'xml'); 1 }, 'a DOCTYPE in a file refuses');
    like($@, qr/^File::Raw::XML: DOCTYPE.* at byte offset 0 near "/, 'with the one message shape');

    $f = write_file('empty.xml', '');
    ok(!eval { file_slurp($f, plugin => 'xml'); 1 }, 'an empty file refuses');
    like($@, qr/no root element/, 'for having no root');

    $f = write_file('latin1.xml', "<r>\xE9</r>");
    ok(!eval { file_slurp($f, plugin => 'xml'); 1 }, 'a file that is not UTF-8 refuses');
    like($@, qr/not UTF-8 at byte offset 3/, 'at the byte');
}

# the other phases
{
    my $f = write_file('s.xml', '<r xmlns="urn:r"><a n="1"><b/></a><x/><a n="2">t</a></r>');
    my @seen;
    File::Raw::each_line($f, sub { push @seen, $_[0]->root->c14n }, plugin => 'xml', record => ['urn:r', 'a']);
    is_deeply(\@seen, ['<a xmlns="urn:r" n="1"><b></b></a>', '<a xmlns="urn:r" n="2">t</a>'],
              'each_line with the xml plugin streams a Document per matching element');
    ok(!eval { File::Raw::each_line($f, sub { push @seen, @_ }, plugin => q{xml}); 1 }, 'without record it refuses');
    like($@, qr/^File::Raw::XML: the xml plugin streams records: pass record/, 'and says what to pass');

    {
        my $doc = File::Raw::XML::file_xml_decode(qq{<r xmlns="urn:r" a="1">t<b/><!-- c --></r>});
        my $w = path('w.xml');   # a call in file_spew's argument list defeats its compile-time checker
        file_spew($w, $doc, plugin => 'xml', indent => 2);
        is(File::Raw::slurp(path('w.xml')), qq{<?xml version="1.0" encoding="UTF-8"?>\n<r xmlns="urn:r" a="1">t<b/><!-- c --></r>},
           'file_spew with the xml plugin writes the document under the writer\'s options');
        ok(file_slurp(path('w.xml'), plugin => 'xml')->equals($doc), 'and it reads back equal');
        my @left = grep { !/^w\.xml$/ && /w\.xml/ } do { opendir my $dh, $dir or die; readdir $dh };
        is_deeply(\@left, [], 'no temporary file is left beside it: File::Raw wrote and renamed');
        ok(!eval { file_spew($w, $doc, plugin => 'xml', encoding => 'perl'); 1 }, 'encoding => perl is refused for a file');
    }
    ok(!eval { file_spew(path('out.xml'), '<r/>', plugin => 'xml'); 1 }, 'spew with the xml plugin refuses a string');
    like($@, qr/^File::Raw::XML: file_spew with the xml plugin takes a File::Raw::XML::Document/, 'saying what it takes');
    ok(!-e path('out.xml'), 'and wrote nothing');
}

# the document outlives its file and its directory
{
    my $tmp = tempdir(CLEANUP => 0);
    my $f = "$tmp/gone.xml";
    open my $fh, '>:raw', $f or die $!;
    print {$fh} '<r><a>text</a></r>';
    close $fh;
    my $doc = file_slurp($f, plugin => 'xml');
    unlink $f;
    rmdir $tmp;
    ok(!-e $tmp, 'the directory is gone');
    is($doc->root->text, 'text', 'and the document still answers');
}

# a chain: gzip then xml, when the gzip plugin is installed
SKIP: {
    skip 'File::Raw::Gzip is not installed', 2
        unless eval { require File::Raw::Gzip; 1 };
    my $f = path('z.xml.gz');
    file_spew($f, '<r><a/></r>', plugin => 'gzip');
    my $doc = eval { file_slurp($f, plugin => ['gzip', 'xml']) };
    ok($doc, 'a gzip then xml chain slurps') or diag $@;
    is($doc && $doc->root->local, 'r', 'and the document is right');
}

done_testing;
