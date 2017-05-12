#!/usr/bin/perl -T

# This script tests the Document interface of HTML::DOM. For the other fea-
# tures, see html-dom.t and html-document.t.

use strict; use warnings; use lib 't';

use Test::More tests => 110;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Tests 2: constructor

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

# -------------------------#
# Tests 3-6: node methods

is $doc ->nodeName, '#document', 'nodeName';;
is $doc->nodeType, 9, 'nodeType';
is_deeply [$doc->nodeValue], [], 'nodeValue';
is_deeply [attributes $doc], [], 'attributes';

# -------------------------#
# Tests 7-11: attributes

is +()=$doc->documentElement, 0,
  'documentElement returns empty list when there is none';

# Open the doc, so we actually have a doc elem.
$doc->open;

# set them first, to make sure they're read-only
doctype $doc 42; implementation $doc 43; documentElement $doc 44;

is_deeply [doctype $doc], [], 'doctype';
{no warnings 'once';
 is implementation $doc, $HTML::DOM::Implementation::it, 'implementation'}
isa_ok documentElement $doc, 'HTML::DOM::Element', 'doc elem';
is documentElement $doc ->tagName, 'HTML', 'tag name of documentElement';

# -------------------------#
# Tests 12-28: constructor methods

{
	isa_ok+(my $elem = createElement $doc eteiGG=>), 
		'HTML::DOM::Element', 'new elem';
	is tagName $elem, ETEIGG=> 'tag name of new elem';
}

{
	isa_ok+(my $frag = createDocumentFragment $doc), 
		'HTML::DOM::DocumentFragment', 'new frag';
	is_deeply [childNodes $frag], [], 'child nodes of new doc frag';
}

{
	isa_ok+(my $text = createTextNode $doc 'eodu'), 
		'HTML::DOM::Text', 'new text node';
	is data $text, 'eodu', 'text of new text node';
}

{
	isa_ok+(my $com = createComment $doc 'eodu'), 
		'HTML::DOM::Comment', 'new comment';
	is data $com, 'eodu', 'text of new comment';
}

eval { createCDATASection $doc };
isa_ok $@, 'HTML::DOM::Exception', '$@ after createCDATASection';
cmp_ok $@, '==', HTML::DOM::Exception::NOT_SUPPORTED_ERR,
	'createCDATASection throws a NOT_SUPPORTED_ERR';

eval { createProcessingInstruction $doc };
isa_ok $@, 'HTML::DOM::Exception', '$@ after createProcessingInstruction';
cmp_ok $@, '==', HTML::DOM::Exception::NOT_SUPPORTED_ERR,
	'createProcessingInstruction throws a NOT_SUPPORTED_ERR';

{
	isa_ok+(my $attr = createAttribute $doc 'eodu'), 
		'HTML::DOM::Attr', 'new attr';
	is nodeName $attr, 'eodu', 'name of new attr';
	is value    $attr, '',     'new attr has no value';
}

eval { createEntityReference $doc };
isa_ok $@, 'HTML::DOM::Exception', '$@ after createEntityReference';
cmp_ok $@, '==', HTML::DOM::Exception::NOT_SUPPORTED_ERR,
	'createEntityReference throws a NOT_SUPPORTED_ERR';

# -------------------------#
# Tests 29-34: getElementsByTagName

{
	$doc->write('
		<div id=one>
			<div id=two>
				<div id=three>
					<b id=bi>aoeu></b>teotn
				</div>
			</div>
			<div id=four>
			</div>
		</div>
	');
	$doc ->close;

	my($div_list, $node_list);

	my @ids = qw[ one two three four ];

	is_deeply [map id $_, getElementsByTagName $doc 'div'], \@ids,
		'getElementsByTagName(div) in list context';

	is_deeply [map id $_, @{
			$div_list = getElementsByTagName $doc 'div'
		}], \@ids,
		'getElementsByTagName(div) in scalar context';

	@ids = qw[ html head body one two three bi four ];

	is_deeply [map $_->id || tag $_, getElementsByTagName $doc '*'],
		\@ids, 'getElementsByTagName(*) in list context';

	is_deeply [map $_->id || tag $_, @{
			$node_list = getElementsByTagName $doc '*'
		}],
		\@ids, 'getElementsByTagName(*) in scalar context';

	# Now let's transmogrify it and make sure the node lists 
	# update properly.

	my($div1,$div2) = $doc->getElementsByTagName('div');
	$div1->removeChild($div2)->delete;

	is_deeply [map id $_, @$div_list], [qw[ one four ]],
		'div node list is updated';

	is_deeply [map $_->id || tag $_, @$node_list],
		[qw[ html head body one four ]], '* node list is updated';
}

# -------------------------#
# Tests 35-110 (18+13+4+17+12+12=76): importNode

use Scalar::Util 'refaddr';
{
	my $other = new HTML::DOM;
	my $frag = $other->createDocumentFragment; # used as a parent for
	                                            # the nodes to be
	# Attr (18):                                  # imported, so we can
	my $elem = $other->createElement('img');       # test that the par-
	(my $node = $other->createAttribute('src'))    # ent attri-
	 ->nodeValue('foo.gif');                       # bute is erased
	$elem->setAttributeNode($node)   ;              
	my $import = $doc->importNode($node);
	cmp_ok refaddr $import, '!=', refaddr $node,
		'importNode(attr) clones it';
	is $import->ownerDocument, $doc, 'ownerDocument of imported attr';
	is +()=$import->parentNode, 0, 'parentNode of imported attr';
	is $import->nodeName, $node->nodeName, 'nodeName of imported attr';
	is $import->nodeType, $node->nodeType, 'nodeType of imported attr';
	is +()=$import->ownerElement, 0,
		'importNode erases an attr’s ownerElement';
	ok $import->specified, 'importNode(attr)->specified';
	# ~~~ I’ll need to test this with an attr that is not specified
	is $import->childNodes->length, 1,
		'childNodes of an imported attr';
	is $import->childNodes->[0]->data, 'foo.gif',
		'contents of the text node of an imported attr';
	
	$import = $doc->importNode($node, 'deeep');
	cmp_ok refaddr $import, '!=', refaddr $node,
		'importNode(attr, deep) clones it';
	is $import->ownerDocument, $doc,
		'ownerDocument of deeply imported attr';
	is +()=$import->parentNode, 0,
		'parentNode of deeply imported attr';
	is $import->nodeName, $node->nodeName,
		'nodeName of recursively imported attr';
	is $import->nodeType, $node->nodeType,
		'nodeType of recursively imported attr';
	is +()=$import->ownerElement, 0,
		'deep importNode erases an attr’s ownerElement';
	ok $import->specified, 'importNode(attr,deep)->specified';
	# ~~~ I’ll need to test this with an attr that is not specified
	is $import->childNodes->length, 1,
		'childNodes of a recursively imported attr';
	is $import->childNodes->[0]->data, 'foo.gif',
		'contents of the text node of a recursively imported attr';
	
	# Frag (13):
	$node = $other->createDocumentFragment;
	for(1..3) { $node->appendChild($other->createTextNode('doodaa')) }
	$import = $doc->importNode($node);
	cmp_ok refaddr $import, '!=', refaddr $node,
		'importNode(doc frag) clones it';
	is $import->ownerDocument, $doc, 'ownerDocument of imported frag';
	is +()=$import->parentNode, 0, 'parentNode of imported frag';
	is $import->nodeName, $node->nodeName, 'nodeName of imported frag';
	is $import->nodeType, $node->nodeType, 'nodeType of imported frag';
	is $import->childNodes->length, 0,
		'number of childNodes of an imported frag';
	
	$import = $doc->importNode($node, 'deep');
	cmp_ok refaddr $import, '!=', refaddr $node,
		'importNode(doc frag, deep) clones it';
	is $import->ownerDocument, $doc,
		'ownerDocument of recursively imported frag';
	is +()=$import->parentNode, 0,
		'parentNode of recursively imported frag';
	is $import->nodeName, $node->nodeName,
		'nodeName of recursively imported frag';
	is $import->nodeType, $node->nodeType,
		'nodeType of recursively imported frag';
	is $import->childNodes->length, 3,
		'number of childNodes of a recursively imported frag';
	cmp_ok join(',', map refaddr $_, $import->childNodes), 'ne',
	       join(',', map refaddr $_, $node->childNodes),
		'childNodes of a recursively imported frag';
	
	# Doc (4):
	eval { importNode $doc $other };
	isa_ok $@, 'HTML::DOM::Exception', '$@ after importing a doc';
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_SUPPORTED_ERR,
		'importNode(doc) throws a NOT_SUPPORTED_ERR';

	eval { importNode $doc $other, 'deep' };
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ after attempting recursively to import a doc';
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_SUPPORTED_ERR,
		'importNode(doc, deep) throws a NOT_SUPPORTED_ERR';

	# Eelem (17):
	$frag->appendChild($node = $other->createElement('a'));
	$node->appendChild($other->createTextNode('doodaa'));
	$node->setAttribute(name => 'lalala');
	$import = $doc->importNode($node);
	cmp_ok refaddr $import, '!=', refaddr $node,
		'importNode(elem) clones it';
	is $import->ownerDocument, $doc, 'ownerDocument of imported elem';
	is +()=$import->parentNode, 0, 'parentNode of imported elem';
	is $import->nodeName, $node->nodeName, 'nodeName of imported elem';
	is $import->nodeType, $node->nodeType, 'nodeType of imported elem';
	is $import->childNodes->length, 0,
		'number of childNodes of an imported elem';
	is $import->getAttribute('name'), 'lalala',
		'elem’s attributes persist in import';
	cmp_ok refaddr $import->getAttributeNode('name'), '!=',
	       refaddr $node  ->getAttributeNode('name'),
		'an elem’s attrs are cloned during import';
	
	$import = $doc->importNode($node, 'deep');
	cmp_ok refaddr $import, '!=', refaddr $node,
		'importNode(elem, deep) clones it';
	is $import->ownerDocument, $doc,
		'ownerDocument of recursively imported elem';
	is +()=$import->parentNode, 0,
		'parentNode of recursively imported elem';
	is $import->nodeName, $node->nodeName,
		'nodeName of recursively imported elem';
	is $import->nodeType, $node->nodeType,
		'nodeType of recursively imported elem';
	is $import->childNodes->length, 1,
		'number of childNodes of a recursively imported elem';
	cmp_ok $import->firstChild, 'ne',
	       $node->firstChild,
		'childNode of a recursively imported elem';
	is $import->getAttribute('name'), 'lalala',
		'elem’s attributes persist through recursive import';
	cmp_ok refaddr $import->getAttributeNode('name'), '!=',
	       refaddr $node  ->getAttributeNode('name'),
		'an elem’s attrs are cloned during recrusive import';
	
	# Text (12):
	$frag->appendChild($node = $other->createTextNode('a'));
	$import = $doc->importNode($node);
	cmp_ok refaddr $import, '!=', refaddr $node,
		'importNode(text) clones it';
	is $import->ownerDocument, $doc, 'ownerDocument of imported text';
	is +()=$import->parentNode, 0, 'parentNode of imported text';
	is $import->nodeName, $node->nodeName, 'nodeName of imported text';
	is $import->nodeType, $node->nodeType, 'nodeType of imported text';
	is $import->data, 'a', 'content of imported text node';
	
	$import = $doc->importNode($node, 'deep');
	cmp_ok refaddr $import, '!=', refaddr $node,
		'importNode(text, deep) clones it';
	is $import->ownerDocument, $doc,
		'ownerDocument of recursively imported text';
	is +()=$import->parentNode, 0,
		'parentNode of recursively imported text';
	is $import->nodeName, $node->nodeName,
		'nodeName of recursively imported text';
	is $import->nodeType, $node->nodeType,
		'nodeType of recursively imported text';
	is $import->data, 'a', 'content of cerursively imported text node';
	
	# Comment (12):
	$frag->appendChild($node = $other->createComment('a'));
	$import = $doc->importNode($node);
	cmp_ok refaddr $import, '!=', refaddr $node,
		'importNode(comet) clones it';
	is $import->ownerDocument, $doc, 'ownerDocument of imported comet';
	is +()=$import->parentNode, 0, 'parentNode of imported comet';
	is $import->nodeName, $node->nodeName,
		'nodeName of imported comet';
	is $import->nodeType, $node->nodeType,
		'nodeType of imported comet';
	is $import->data, 'a', 'content of imported comet';
	
	$import = $doc->importNode($node, 'deep');
	cmp_ok refaddr $import, '!=', refaddr $node,
		'importNode(comet, deep) clones it';
	is $import->ownerDocument, $doc,
		'ownerDocument of recursively imported comet';
	is +()=$import->parentNode, 0,
		'parentNode of recursively imported comet';
	is $import->nodeName, $node->nodeName,
		'nodeName of recursively imported comet';
	is $import->nodeType, $node->nodeType,
		'nodeType of recursively imported comet';
	is $import->data, 'a', 'content of cerursively imported comet';
	
}

