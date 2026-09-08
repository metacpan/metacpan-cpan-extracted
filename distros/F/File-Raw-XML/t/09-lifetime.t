#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr weaken);
use File::Raw::XML qw(file_xml_decode);

# A node keeps its document alive; nothing else does, and nothing has to.

# a node outlives the document lexical
{
    my $node;
    {
        my $doc = file_xml_decode('<a><b/></a>');
        ($node) = $doc->root->elements;
    }
    is($node->local, 'b', 'a node kept after the document lexical is gone still answers');
    is($node->parent->local, 'a', 'and so does its parent');
}

# $node->doc is the same object
{
    my $doc  = file_xml_decode('<a/>');
    my $node = $doc->root;
    is(refaddr($node->doc), refaddr($doc), '$node->doc is the same referent as the document');
    isa_ok($node->doc, 'File::Raw::XML::Document');
}

# a detached node holds the document as any node does
{
    my $doc  = file_xml_decode('<a><b>text</b></a>');
    my $weak = $doc;
    weaken($weak);
    my ($b) = $doc->root->elements;
    $b->detach;
    undef $doc;
    ok(defined $weak, 'a detached node keeps its document alive');
    is($b->text, 'text', 'and still answers');
    undef $b;
    ok(!defined $weak, 'the document is freed when the detached node dies');
}

# the document dies with its last node, and not before
{
    my $doc  = file_xml_decode('<a><b/><c/></a>');
    my $weak = $doc;
    weaken($weak);
    my ($b, $c) = $doc->root->elements;
    undef $doc;
    ok(defined $weak, 'the document is alive while two nodes hold it');
    undef $b;
    ok(defined $weak, 'and while one does');
    undef $c;
    ok(!defined $weak, 'and is freed when the last node goes');
}

# a node held in a global survives to global destruction without a word
{
    my @inc = map { "-I$_" } grep { m{blib} } @INC;
    my $out = `$^X -w @inc -MFile::Raw::XML=file_xml_decode -e 'our \$N = file_xml_decode("<a><b/></a>")->root; print \$N->local' 2>&1`;
    is($out, 'a', 'a global node is fine at global destruction, with no warning');
}

# the wrong invocant croaks naming the method
{
    my $doc  = file_xml_decode('<a/>');
    my $node = $doc->root;
    ok(!eval { File::Raw::XML::Node::local($doc); 1 }, 'a Node method on a Document dies');
    like($@, qr/^File::Raw::XML: local: the invocant is not a File::Raw::XML::Node/, 'naming the method and the class');
    ok(!eval { File::Raw::XML::Document::root($node); 1 }, 'a Document method on a Node dies');
    like($@, qr/^File::Raw::XML: root: the invocant is not a File::Raw::XML::Document/, 'naming the method and the class');
    ok(!eval { File::Raw::XML::Document::root(bless {}, 'File::Raw::XML::Document'); 1 }, 'a hash blessed into the class is not a document');
    like($@, qr/not a File::Raw::XML::Document/, 'blessing does not make it one: the magic does');
    ok(!eval { File::Raw::XML::Node::kind(undef); 1 }, 'undef is not a node');
    ok(!eval { File::Raw::XML::Node::kind('x'); 1 }, 'nor is a string');
}

# many documents, many nodes, no crossing
{
    my @docs  = map { file_xml_decode("<d$_/>") } 1 .. 20;
    my @roots = map { $_->root } @docs;
    @docs = ();
    is_deeply([map { $_->local } @roots], [map { "d$_" } 1 .. 20], 'twenty documents held only by their roots all answer');
    is(refaddr($roots[3]->doc), refaddr($roots[3]->doc), 'doc is stable');
    isnt(refaddr($roots[3]->doc), refaddr($roots[4]->doc), 'and distinct across documents');
}

done_testing;
