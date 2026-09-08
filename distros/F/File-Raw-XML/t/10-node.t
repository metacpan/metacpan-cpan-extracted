#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(:all);

# Every accessor on every kind, and the undef-versus-'' namespace rule.

my $xml = '<?pi top?><r xmlns="urn:d" xmlns:p="urn:p" a="1" p:a="2" b="3">'
        . '<!-- c -->x<p:e id="e1">y<![CDATA[z]]></p:e><e/><?q data?></r>';
my $doc  = file_xml_decode($xml, id_attrs => ['id']);
my $root = $doc->root;

# kinds
is($root->kind, FRX_ELEMENT, 'the root is an element');
is($doc->document->kind, FRX_DOCUMENT, 'the document node is a document');
my @kids = $root->children;
is(scalar @kids, 5, 'five children: comment, text, element, element, pi');
is_deeply([map { $_->kind } @kids], [FRX_COMMENT, FRX_TEXT, FRX_ELEMENT, FRX_ELEMENT, FRX_PI], 'in order, by kind');
is_deeply([FRX_ELEMENT, FRX_TEXT, FRX_COMMENT, FRX_PI, FRX_DOCUMENT], [1 .. 5], 'the constants are 1 to 5');

# names
is($root->ns,     'urn:d', 'ns');
is($root->prefix, '',      'prefix is the empty string when there is none');
is($root->local,  'r',     'local');
is($root->name,   'r',     'name');
my $pe = $kids[2];
is($pe->ns,     'urn:p', 'a prefixed element resolves its namespace');
is($pe->prefix, 'p',     'and reports its prefix');
is($pe->local,  'e',     'and local name');
is($pe->name,   'p:e',   'and qualified name as written');
is($kids[3]->ns, 'urn:d', 'an unprefixed child is in the default namespace');
is($kids[4]->local, 'q',    'a PI\'s target is its local');
is($kids[4]->text,  'data', 'and its data is its text');
is($kids[0]->text,  ' c ',  'a comment\'s body is its text');
is($kids[1]->text,  'x',    'a text node\'s value is its text');
is($kids[0]->ns, '', 'a comment has no namespace');
is($kids[0]->name, '', 'nor a name');

# attributes
is($root->attr('a'), '1', 'attr by local name: the first in document order');
is($root->attr('b'), '3', 'another');
is($root->attr('nope'), undef, 'a missing attribute is undef');
is($root->attr_ns(undef, 'a'), '1', 'attr_ns with undef: any namespace, first wins');
is($root->attr_ns('', 'a'),    '1', 'attr_ns with the empty string: the unprefixed one');
is($root->attr_ns('urn:p', 'a'), '2', 'attr_ns with a namespace: the prefixed one');
is($root->attr_ns('urn:d', 'a'), undef, 'an unprefixed attribute is not in the default namespace');
is_deeply($root->attrs, [['', '', 'a', '1'], ['urn:p', 'p', 'a', '2'], ['', '', 'b', '3']],
          'attrs: [uri, prefix, local, value] in document order, declarations absent');
is_deeply($kids[1]->attrs, [], 'a text node has no attributes');

# children, elements, find, descendants
is_deeply([map { $_->local } $root->elements], ['e', 'e'], 'elements: only the element children');
is_deeply([map { $_->name } $root->find(undef, 'e')], ['p:e', 'e'], 'find with undef: both');
is_deeply([map { $_->name } $root->find('urn:p', 'e')], ['p:e'], 'find with a namespace');
is_deeply([map { $_->name } $root->find('urn:d', 'e')], ['e'], 'find with the default namespace');
is_deeply([map { $_->name } $root->find('', 'e')], [], 'find with no namespace: neither, both are in one');
is_deeply([map { $_->name } $root->find(undef, 'zz')], [], 'find of nothing is an empty list');

my $deep = file_xml_decode('<r><a><b><a/></b></a><a/></r>')->root;
is_deeply([map { $_->parent->local } $deep->descendants(undef, 'a')], ['r', 'b', 'r'], 'descendants in document order, by their parents');
is(scalar(my @b = $deep->descendants(undef, 'b')), 1, 'one b among the descendants');

# text
is($root->text, 'xyz', 'text of an element: every descendant text run, in order');
is($pe->text,   'yz',  'text across a CDATA merge');
is($doc->document->text, 'xyz', 'text of the document node is the root\'s');
is(file_xml_decode('<r>&lt;&#xe9;</r>')->root->text, "<\x{e9}", 'references decoded, as characters');
ok(utf8::is_utf8(file_xml_decode('<r>a</r>')->root->text), 'text is a character string');
ok(utf8::is_utf8(file_xml_decode("<\xC3\xA9/>")->root->local), 'and so is a name');
is(file_xml_decode("<\xC3\xA9/>")->root->local, "\x{e9}", 'with the right characters');

# parent chain
is($pe->parent->local, 'r', 'parent');
is($pe->parent->parent->kind, FRX_DOCUMENT, 'the root\'s parent is the document node');
is($pe->parent->parent->parent, undef, 'and above that, undef');
is_deeply([map { $_->kind } $doc->document->children], [FRX_PI, FRX_ELEMENT], 'the document node\'s children: the top-level PI and the root');

# by_id
is($doc->by_id(id => 'e1')->name, 'p:e', 'by_id hit');
is($doc->by_id(id => 'nope'), undef, 'by_id miss');
is($doc->by_id(ID => 'e1'), undef, 'by_id with an unindexed name');

done_testing;
