#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);
use File::Raw::XML qw(:all);

# The mutable tree: every operation on a fresh document and on a parsed
# one, every refusal with its message, the namespace fixup matrix, the ID
# index under edits, foreign nodes, and lifetime through detach and free.
# The deliverable: the enveloped-signature case built by hand
# canonicalises to the parsed fixture's bytes, and detaching the Signature
# gives what `without` gave.

my $SAML = 'urn:oasis:names:tc:SAML:2.0:assertion';
my $DS   = 'http://www.w3.org/2000/09/xmldsig#';

sub refused { my ($code) = @_; my $ok = eval { $code->(); 1 }; $ok ? '' : $@ }

# the deliverable
{
    my $fixture = file_xml_decode(<<"XML", id_attrs => ['ID']);
<saml:Assertion xmlns:saml="$SAML" ID="a1" Version="2.0"><saml:Issuer>idp</saml:Issuer><ds:Signature xmlns:ds="$DS"><ds:SignedInfo/><ds:SignatureValue>x</ds:SignatureValue></ds:Signature><saml:Subject><saml:NameID>u</saml:NameID></saml:Subject></saml:Assertion>
XML
    my ($sig) = $fixture->root->find($DS, 'Signature');

    my $doc  = File::Raw::XML->new_document;
    my $root = $doc->new_element($SAML, 'saml:Assertion');
    $doc->document->append($root);
    $root->set_attr('', 'ID', 'a1')->set_attr('', 'Version', '2.0');
    $root->append($doc->new_element($SAML, 'saml:Issuer'))->set_text('idp');
    my $signature = $root->append($doc->new_element($DS, 'ds:Signature'));
    $signature->append($doc->new_element($DS, 'ds:SignedInfo'));
    $signature->append($doc->new_element($DS, 'ds:SignatureValue'))->set_text('x');
    $root->append($doc->new_element($SAML, 'saml:Subject'))->append($doc->new_element($SAML, 'saml:NameID'))->set_text('u');

    is($root->c14n, $fixture->root->c14n, 'built by hand, the assertion canonicalises to the parsed fixture\'s bytes');
    is($root->c14n(mode => 'inclusive'), $fixture->root->c14n(mode => 'inclusive'), 'under inclusive too');
    ok($doc->equals($fixture), 'and the documents are equal');
    is($doc->to_string(declaration => 0), $fixture->to_string(declaration => 0), 'and write the same');
    my $detached = $signature->detach;
    is($root->c14n, $fixture->root->c14n(without => [$sig]), 'detaching the Signature gives the bytes without gave');
    is($detached->c14n, $sig->c14n, 'and the detached signature still canonicalises, with its own declaration');
    ok(!defined $detached->parent, 'a detached node has no parent');
    my ($subject) = $root->find($SAML, 'Subject');
    $subject->insert_before($detached);
    is($root->c14n, $fixture->root->c14n, 'put back where it was, the bytes are back');
}

# every operation on a fresh document
{
    my $doc = File::Raw::XML->new_document;
    is($doc->version, '1.0', 'a new document is 1.0');
    is(File::Raw::XML->new_document(version => '1.1')->version, '1.1', 'or 1.1 when asked');
    like(refused(sub { File::Raw::XML->new_document(version => '2') }), qr/version must be 1\.0 or 1\.1/, 'not 2');
    like(refused(sub { File::Raw::XML->new_document(bogus => 1) }), qr/the one option is version/, 'the one option');
    is($doc->to_string, qq{<?xml version="1.0" encoding="UTF-8"?>\n}, 'empty: the declaration alone');
    is($doc->c14n, '', 'and nothing to canonicalise');

    my $r = $doc->new_element('', 'r');
    isa_ok($r, 'File::Raw::XML::Node');
    is($r->kind, FRX_ELEMENT, 'an element');
    ok(!defined $r->parent, 'detached at birth');
    is($doc->document->append($r)->local, 'r', 'append returns the child');
    is($doc->root->local, 'r', 'and it is the root');
    like(refused(sub { $doc->document->append($doc->new_element('', 'r2')) }), qr/a document has one root element/, 'a second root is refused');
    $doc->document->append($doc->new_comment(' top '));
    $doc->root->insert_before($doc->new_pi('pi', 'data'));
    like(refused(sub { $doc->document->append($doc->new_text('x')) }), qr/text is not allowed outside the root element/, 'text under the document is refused');
    is($doc->to_string(declaration => 0), qq{<?pi data?>\n<r/>\n<!-- top -->}, 'the top level in order: PI before, comment after');

    my $a = $r->append($doc->new_element('', 'a'));
    my $b = $r->append($doc->new_element('', 'b'));
    my $t = $r->append($doc->new_text('tail'));
    $b->insert_before($doc->new_element('', 'between'));
    is($r->to_string, '<r><a/><between/><b/>tail</r>', 'append and insert_before place children');
    is_deeply([ map { $_->kind == FRX_TEXT ? 'text' : $_->local } $r->children ], [qw(a between b text)], 'children in order');
    $a->set_attr('', 'x', '1')->set_attr('', 'y', ' 2 & "q" ');
    is($a->to_string, '<a x="1" y=" 2 &amp; &quot;q&quot; "/>', 'set_attr adds, values escaped on the way out');
    $a->set_attr('', 'x', '3');
    is($a->attr('x'), '3', 'set_attr replaces');
    is(scalar @{ $a->attrs }, 2, 'without a duplicate');
    $a->remove_attr('', 'y');
    is($a->to_string, '<a x="3"/>', 'remove_attr');
    $a->remove_attr('', 'nope');
    is($a->to_string, '<a x="3"/>', 'removing what is not there is nothing');
    $b->set_text('one');
    $b->set_text('two');
    is($b->to_string, '<b>two</b>', 'set_text on an element replaces the content, it does not append');
    $t->set_text('TAIL');
    is($t->text, 'TAIL', 'set_text on a text node replaces its value');
    $b->set_name('', 'bee');
    is($r->to_string, '<r><a x="3"/><between/><bee>two</bee>TAIL</r>', 'set_name renames');
    my $c = $doc->new_comment('c');
    $c->set_text('changed');
    is($c->text, 'changed', 'set_text on a comment');
    like(refused(sub { $c->set_text('a--b') }), qr/-- is not allowed inside a comment/, 'but not to -- ');
    my $pi = $doc->new_pi('p');
    is($pi->to_string, '<?p?>', 'a PI with no data');
    like(refused(sub { $pi->set_text('a?>b') }), qr/\?> is not allowed inside a processing instruction/, 'PI data is checked');
    like(refused(sub { $doc->new_pi('xml', 'x') }), qr/the xml target is reserved/, 'the xml target');
    like(refused(sub { $doc->new_text("bad\x{1}") }), qr/not an XML character/, 'a control character in text');
    ok(File::Raw::XML->new_document(version => '1.1')->new_text("ok\x{1}"), 'which 1.1 admits');
    like(refused(sub { $doc->new_element('', '1x') }), qr/the local name is not a name/, 'a bad element name');
    like(refused(sub { $doc->new_element('', 'p:x') }), qr/a prefix needs a namespace name/, 'a prefix without a namespace');
    like(refused(sub { $doc->new_element('urn:x', 'a:b:c') }), qr/local name is not a name|prefix is not a name/, 'two colons');
    like(refused(sub { $doc->new_element('x', 'e') }), qr/relative namespace URI is refused/, 'a relative namespace');
    like(refused(sub { $doc->new_element('urn:x', 'xmlns:e') }), qr/xmlns prefix/, 'the xmlns prefix');
    like(refused(sub { $r->set_attr('urn:x', 'plain', 'v') }), qr/attribute with a namespace needs a prefix/, 'a namespaced attribute needs a prefix');
    like(refused(sub { $r->set_attr('', 'xmlns', 'urn:x') }), qr/xmlns is a declaration; use declare_ns/, 'xmlns is not an attribute');
    like(refused(sub { $r->append($r) }), qr/has a parent|under itself/, 'a node under itself');
    my $orphan = $doc->new_element('', 'o');
    like(refused(sub { $orphan->append($r) }), qr/the node has a parent; detach it first/, 'appending an attached node');
    like(refused(sub { $orphan->insert_before($doc->new_element('', 'q')) }), qr/reference node has no parent/, 'insert_before under nothing');
    like(refused(sub { $t->append($doc->new_element('', 'q')) }), qr/only an element or the document node has children/, 'a text node has no children');
    like(refused(sub { $doc->document->detach }), qr/document node cannot be detached/, 'the document node stays');
    like(refused(sub { $doc->import($doc->document) }), qr/document node cannot be imported/, 'nor is it imported');
    ok($orphan->detach, 'detaching a node with no parent is nothing');
}

# the namespace fixup matrix: bound, unbound, rebound, default
{
    my $doc = File::Raw::XML->new_document;
    my $root = $doc->document->append($doc->new_element('urn:d', 'root'));
    $root->declare_ns('p', 'urn:p');
    is($root->to_string, '<root xmlns="urn:d" xmlns:p="urn:p"/>', 'the root declares its own default and p');

    # bound: p means urn:p here, nothing to add
    my $bound = $root->append($doc->new_element('urn:p', 'p:bound'));
    is($bound->to_string(), '<p:bound xmlns="urn:d" xmlns:p="urn:p"/>', 'a node written alone carries the bindings in scope, in the order the element declaring them holds them');
    is($root->to_string, '<root xmlns="urn:d" xmlns:p="urn:p"><p:bound/></root>', 'in place, no declaration was added: p was bound');

    # unbound: q is not declared anywhere, so the appended element declares it
    my $unbound = $root->append($doc->new_element('urn:q', 'q:unbound'));
    is($unbound->to_string, '<q:unbound xmlns:q="urn:q" xmlns="urn:d" xmlns:p="urn:p"/>', 'unbound: declared on the appended element');
    is($doc->root->c14n, '<root xmlns="urn:d"><p:bound xmlns:p="urn:p"></p:bound><q:unbound xmlns:q="urn:q"></q:unbound></root>', 'and the canonical form has it where it is used');

    # rebound: p means something else on the appended element's own subtree
    my $rebound = $root->append($doc->new_element('urn:other', 'p:rebound'));
    is($rebound->ns, 'urn:other', 'the element keeps its namespace');
    like($rebound->to_string, qr/^<p:rebound xmlns:p="urn:other"/, 'and shadows p with its own declaration');
    is(file_xml_decode($doc->to_string)->root->c14n, $doc->root->c14n, 'what is written parses back to the same canonical form');

    # default: an unprefixed element with a namespace under a different
    # default declares the default on itself, which reaches nothing else
    my $other = $root->append($doc->new_element('urn:e', 'unprefixed'));
    is($other->to_string, '<unprefixed xmlns="urn:e" xmlns:p="urn:p"/>', 'an unprefixed element in another namespace declares the default on itself');
    is($other->ns, 'urn:e', 'and keeps its namespace');
    is($bound->ns, 'urn:p', 'the sibling before it is untouched');
    is($root->ns, 'urn:d', 'and so is the parent whose default it shadows');
    my $none = $root->append($doc->new_element('', 'nons'));
    is($none->to_string, '<nons xmlns="" xmlns:p="urn:p"/>', 'an element with no namespace under a default gets xmlns=""');
    is($none->ns, '', 'and has none');
    my $again = file_xml_decode($doc->to_string);
    ok($again->equals($doc), 'the whole thing parses back equal');

    # a subtree moved: its chain is re-rooted and what it relied on above comes along
    my $src = file_xml_decode('<r xmlns:a="urn:a" xmlns="urn:def"><a:x><y/></a:x></r>');
    my ($ax) = $src->root->elements;
    $ax->detach;
    my $dst = File::Raw::XML->new_document;
    my $droot = $dst->document->append($dst->new_element('', 'dst'));
    like(refused(sub { $droot->append($ax) }), qr/belongs to another document; use import/, 'a foreign node is refused');
    my $copy = $dst->import($ax);
    ok(!defined $copy->parent, 'import gives a detached copy');
    $droot->append($copy);
    is($droot->to_string, '<dst><a:x xmlns:a="urn:a" xmlns="urn:def"><y/></a:x></dst>', 'the import carries the bindings in scope at its source');
    is($copy->ns, 'urn:a', 'with its namespace');
    my ($y) = $copy->elements;
    is($y->ns, 'urn:def', 'and the default its child relied on');
    undef $src; undef $ax;
    is($y->ns, 'urn:def', 'the copy outlives the source document');

    # set_attr with a prefix declares where needed
    $droot->set_attr('urn:z', 'z:attr', 'v');
    is($droot->to_string, '<dst xmlns:z="urn:z" z:attr="v"><a:x xmlns:a="urn:a" xmlns="urn:def"><y/></a:x></dst>', 'a prefixed attribute declares its prefix on the element');
    like(refused(sub { $droot->declare_ns('xmlns', 'urn:x') }), qr/xmlns prefix cannot be declared/, 'declare_ns refuses xmlns');
    like(refused(sub { $droot->declare_ns('p', '') }), qr/cannot be undeclared/, 'and undeclaring a prefix');
    like(refused(sub { $droot->declare_ns('p', 'rel') }), qr/relative namespace URI/, 'and a relative URI');
    ok($droot->declare_ns('xml', 'http://www.w3.org/XML/1998/namespace'), 'xmlns:xml with the right URI is accepted and dropped');
    like(refused(sub { $droot->declare_ns('xml', 'urn:x') }), qr/xml prefix is bound to its own namespace/, 'and refused with another');
}

# the ID index under edits
{
    my $doc = file_xml_decode('<r><a ID="one"/><b ID="two"><c/></b></r>', id_attrs => ['ID']);
    my ($a, $b) = $doc->root->elements;
    my ($c) = $b->elements;
    is($doc->by_id(ID => 'two')->local, 'b', 'the parsed index');
    my $before = $doc->c14n;
    like(refused(sub { $c->set_attr('', 'ID', 'one') }), qr/another element carries that ID value already/, 'a duplicate ID is refused');
    is($doc->c14n, $before, 'with the tree unchanged');
    $c->set_attr('', 'ID', 'three');
    is($doc->by_id(ID => 'three')->local, 'c', 'a new ID is found');
    $a->set_attr('', 'ID', 'uno');
    ok(!defined $doc->by_id(ID => 'one'), 'the replaced value is gone');
    is($doc->by_id(ID => 'uno')->local, 'a', 'and the new one there');
    $a->remove_attr('', 'ID');
    ok(!defined $doc->by_id(ID => 'uno'), 'remove_attr removes the entry');
    $b->detach;
    ok(!defined $doc->by_id(ID => 'two') && !defined $doc->by_id(ID => 'three'), 'detaching a subtree removes its entries');
    $doc->root->set_attr('', 'ID', 'three');
    like(refused(sub { $doc->root->append($b) }), qr/attached subtree carries an ID value the document already has/, 'and re-attaching it with a value now taken is refused');
    $doc->root->remove_attr('', 'ID');
    $doc->root->append($b);
    is($doc->by_id(ID => 'three')->local, 'c', 'attached again, its entries are back');
    my $fresh = File::Raw::XML->new_document;
    ok(!defined $fresh->by_id(ID => 'x'), 'a new document indexes nothing without id_attrs');
}

# edits on a parsed document, and the writer and c14n over them
{
    my $doc = file_xml_decode('<r xmlns="urn:r"><keep/><drop>x</drop></r>', profile => 'full');
    my ($keep, $drop) = $doc->root->elements;
    $drop->detach;
    my $chars = "t\x{e9}";
    utf8::upgrade($chars);
    like(refused(sub { $keep->set_text("t\x{e9}") }), qr/not UTF-8/,
         'an edit takes strings the way the codec does: unflagged Latin-1 bytes are refused');
    $keep->append($doc->new_element('urn:r', 'added'))->set_text($chars);
    is($doc->root->c14n, "<r xmlns=\"urn:r\"><keep><added>t\xC3\xA9</added></keep></r>", 'c14n over an edited parsed tree');
    is($doc->to_string(declaration => 0, encoding => 'US-ASCII'), '<r xmlns="urn:r"><keep><added>t&#xE9;</added></keep></r>', 'and the writer');
    ok(file_xml_decode($doc->to_string)->equals($doc), 'which parses back equal');
    is($drop->text, 'x', 'the detached subtree is still readable');
}

# lifetime: a detached node keeps its document alive; a created one holds it
{
    my $weak;
    my $node;
    {
        my $doc = File::Raw::XML->new_document;
        $weak = $doc;
        weaken($weak);
        my $root = $doc->document->append($doc->new_element('', 'r'));
        $node = $root->append($doc->new_element('', 'kid'));
        $node->detach;
    }
    ok(defined $weak, 'the document lives while a detached node holds it');
    is($node->local, 'kid', 'and the node answers');
    undef $node;
    ok(!defined $weak, 'and is freed with the last node');
}

done_testing;
