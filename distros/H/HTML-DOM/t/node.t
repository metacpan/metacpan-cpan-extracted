#!/usr/bin/perl -T

# This script tests the Node interface. Since objects are never blessed
# into the HTML::DOM::Node class (it does have a 'new' method,  but you
# won't tell anyone, will you?), I am using a document fragment to test
# most of the interface.  The DocumentFragment interface  (supposedly)
# doesn't have any methods of its own,  but only those  in  inherits
# from Node.

# There are also tests in here for HTML::Element’s methods that are over-
# ridden by HTML::DOM::Node.

use strict; use warnings; use lib 't';

use Test::More tests => scalar reverse '801';


# -------------------------#
# Tests 1-2: load the modules

BEGIN { use_ok 'HTML::DOM'; }
BEGIN { &use_ok(qw'HTML::DOM::Node :all'); } # & so I can use qw

# -------------------------#
# Tests 3-14: constants

{
	my $x;

	for (qw/ ELEMENT_NODE ATTRIBUTE_NODE TEXT_NODE CDATA_SECTION_NODE
	        ENTITY_REFERENCE_NODE ENTITY_NODE
	      PROCESSING_INSTRUCTION_NODE COMMENT_NODE DOCUMENT_NODE
	   DOCUMENT_TYPE_NODE DOCUMENT_FRAGMENT_NODE NOTATION_NODE /) {
		eval "is $_, " . ++$x . ", '$_'";
	}
}



# -------------------------#
# Tests 15-17: constructor

my $doc = new HTML::DOM; $doc->open;
isa_ok $doc, 'HTML::DOM';
my $frag = $doc->createDocumentFragment;
isa_ok $frag, 'HTML::DOM::DocumentFragment';
isa_ok $frag, 'HTML::DOM::Node'; # make sure it's node we're testing

my $another_doc = new HTML::DOM; # we need this in various places

# -------------------------#
# Tests 18-35: attributes

# wq/nodeName nodeValue nodeType/ are implemented by subclasses

{
	isa_ok my $root_elem = $doc->documentElement, 'HTML::DOM::Node';
		# just to make sure we're testing the node interface
	cmp_ok $root_elem->parentNode, '==', $doc, 'parentNode';
}

is_deeply [  childNodes $frag ], [], 'no childNodes in list context';
is_deeply [@{childNodes $frag}], [], 'no childNodes in scalar context';
is_deeply [  firstChild $frag ], [], 'firstChild is null';
is_deeply [   lastChild $frag ], [], 'lastChild is null';

# Next we'll give our doc frag a few child nodes to play withal (and we'll
# need to do this later, too, so it's in a subroutine).
sub fill_frag($) {
	my $frag = shift;
	(my $child = createElement $doc 'div')->id('wunne');
	appendChild $frag $child;
	(   $child = createElement $doc 'div')->id('tioux');
	appendChild $frag $child;
	(   $child = createElement $doc 'div')->id('three');
	appendChild $frag $child;
}
fill_frag $frag;

is_deeply [map id $_, childNodes $frag], [qw/ wunne tioux three /],
	'childNodes in list context';
is_deeply [map id $_, @{childNodes $frag}], [qw/ wunne tioux three /],
	'childNodes in scalar context';

is id{firstChild $frag}, 'wunne', 'firstChild';
is id{ lastChild $frag}, 'three',  'lastChild';

is_deeply [previousSibling $frag], [], 'null previousSibling';
is_deeply [nextSibling $frag], [], 'null nextSibling';

# make sure we're testing node methods
cmp_ok firstChild $frag ->can('nextSibling'), '==',
	HTML::DOM::Node->can('nextSibling'),
	'we\'re testing the right nextSibling';
cmp_ok childNodes $frag ->[1]->can('previousSibling'), '==',
	HTML::DOM::Node->can('previousSibling'),
	'we\'re testing the right previousSibling';

is id{nextSibling{(childNodes $frag)[0]}}, 'tioux', 'nextSibling';
is id{previousSibling{(childNodes $frag)[1]}}, 'wunne', 'previousSibling';

is_deeply [attributes $frag], [], 'attributes';

cmp_ok ownerDocument $frag, '==', $doc, 'ownerDocument';


# -------------------------#
# Tests 36-47: insertBefore

{
	$frag->insertBefore(my $elem = $doc->createElement('div'));
	$elem ->id('phour');
	is_deeply [map id $_, childNodes $frag],
		[qw/wunne tioux three phour/],
		'insertBefore with a null 2nd arg';

	$frag->insertBefore((childNodes $frag)[-1,0]);
	is_deeply [map id $_, childNodes $frag],
		[qw/phour wunne tioux three/],
		'insertBefore removes from the tree first';

	$elem = createElement $doc 'p';
	$elem->insertBefore($frag);
	is_deeply [map id $_, childNodes $elem],
		[qw/phour wunne tioux three/],
		'insertBefore(frag) inserts the frag\'s children';

	SKIP :{
		skip 'not implemented yet', 2;
		eval {
			$frag->insertBefore(
				createAttribute $doc 'ddk'
			);
		};
		isa_ok $@, 'HTML::DOM::Exception',
			'$@ (after insertBefore with wrong node type)';
		cmp_ok $@, '==', 
			HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
			'insertBefore with wrong node type throws a ' .
			'hierarchy error';
	}
	
	eval {
		($elem->childNodes)[0]->insertBefore(
			$elem
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after insertBefore with an ancestor node)';
	cmp_ok $@, '==', HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
	    'insertBefore with an ancestor node throws a hierarchy error';

	my $other_elem = createElement $another_doc 'ddk';
	ok eval {
		$frag->insertBefore(
			$other_elem
		);
		1
	}, 'insertBefore with wrong doc no longer dies';
	is $other_elem->ownerDocument, $frag->ownerDocument,
	 'insertBefore with wrong doc sets the owner doc';

	eval {
		$frag->insertBefore(
			$doc->createElement('ddk'), $elem
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after insertBefore with a bad refChild)';
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_FOUND_ERR,
		'insertBefore with a 2nd arg that\'s not a child of ' .
		'this node throws a "not found" error';

	# We need to make sure that $doc->insertBefore doesn’t throw a
	# wrong doc error, due to $doc’s ownerDocument’s being null.
	my $dock = new HTML::DOM;
	ok eval{
	    $dock->insertBefore($dock->createComment('unoeunoth'),undef); 1
	}, '$doc->insertBefore doesn’t produce an invalid wrong doc error'
	  or diag $@;
}

# -------------------------#
# Tests 48-60: replaceChild

# insertBefore messed up our frag, so let's make a new one.
fill_frag($frag = createDocumentFragment $doc);

{
	is id{$frag->replaceChild((childNodes $frag)[0,2])}, 'three',
		'replaceChild returns the replaced node';
	is_deeply [map id $_, childNodes $frag],
		[qw/tioux wunne/],
		'replaceChild removes from the tree first';

	(my $elem = createElement $doc 'p')->appendChild(
		my $node = createTextNode $doc 'lalala');
	$elem->replaceChild($frag, $node);
	is_deeply [map id $_, childNodes $elem],
		[qw/tioux wunne/],
		'replaceChild(frag,node) inserts the frag\'s children';

	SKIP :{
		skip 'not implemented yet', 2;
		eval {
			$frag->appendChild(
				my $node = createTextNode $doc 'ooo');
			$frag->replaceChild(
				(createAttribute $doc 'ddk'), $node
			);
		};
		isa_ok $@, 'HTML::DOM::Exception',
			'$@ (after replaceChild with wrong node type)';
		cmp_ok $@, '==',
			HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
			'replaceChild with wrong node type throws a ' .
			'hierarchy error';
	}
	
	eval {
		(my $node = ($elem->childNodes)[0])->appendChild(
			my $text_node = createTextNode $doc 'oetot');
		$node->replaceChild(
			$elem, $text_node
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after replaceChild with an ancestor node)';
	cmp_ok $@, '==', HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
	    'replaceChild with an ancestor node throws a hierarchy error';

	my $other_elem = createElement $another_doc 'ddk';
	ok eval {
		$elem->replaceChild(
			($other_elem),
			(childNodes $elem)[0],
		);
		1
	}, 'replaceChild with wrong doc no longer dies';
	is $other_elem->ownerDocument, $elem->ownerDocument,
	 'replaceChild with wrong doc sets the owner doc';

	eval {
		$frag-> replaceChild(
			$doc->createElement('ddk'), $elem
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after replaceChild with a bad refChild)';
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_FOUND_ERR,
		'replaceChild with a 2nd arg that\'s not a child of ' .
		'this node throws a "not found" error';

	my $dock = new HTML::DOM; $dock->open;
	$dock->close; # avoid messing up the parser with this test
	ok eval{
	    $dock->replaceChild(
		$dock->createElement('html'),$dock->firstChild
	    ); 1
	}, '$doc->replaceChild doesn’t produce an invalid wrong doc error'
	 or diag $@;

	$dock->write('<p id=foo><a></a></p>');
	is $dock->getElementById('foo')->replaceChild(
		$dock->createElement('b'),
		$dock->getElementsByTagName('a')->[0]
	)->ownerDocument, $dock,
		'implicit ownerDocument is made explicit by replaceChild';
	
}

# -------------------------#
# Tests 61-6: removeChild

# replaceChild messed up our frag, so let's make a new one.
fill_frag($frag = createDocumentFragment $doc);

{
	is id{$frag->removeChild((childNodes $frag)[0])}, 'wunne',
		'removeChild returns the removed node';
	is_deeply [map id $_, childNodes $frag],
		[qw/tioux three/],
		'removeChild removes the node';

	eval {
		$frag-> removeChild(
			$doc->createElement('br')
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after removeChild with a bad arg)';
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_FOUND_ERR,
		'removeChild with an arg that\'s not a child of ' .
		'this node throws a "not found" error';

	(my $dock = new HTML::DOM)->write("<p id=foo><b id=bar></b></p>");
	is $dock->getElementById('foo')->removeChild(
		$dock->getElementById('bar')
	)->ownerDocument, $dock,
		'implicit ownerDocument is made explicit by removeChild';
	
	ok eval{$dock->removeChild($dock->firstChild)},
		'$doc->removeChild doesn\'t kick the bucket';
}

# -------------------------#
# Tests 67-76: appendChild

# removeChild messed up our frag, so let's make a new one.
fill_frag($frag = createDocumentFragment $doc);

{
	is id{$frag-> appendChild((childNodes $frag)[0])}, 'wunne',
		'appendChild returns the added node';
	is_deeply [map id $_, childNodes $frag],
		[qw/tioux three wunne/],
		'appendChild removes from the tree first';

	(my $elem = createElement $doc 'p')->appendChild($frag);
	is_deeply [map id $_, childNodes $elem],
		[qw/tioux three wunne/],
		'appendChild(frag) inserts the frag\'s children';

	SKIP :{
		skip 'not implemented yet', 2;
		eval {
			$frag-> appendChild(
				(createAttribute $doc 'ddk')
			);
		};
		isa_ok $@, 'HTML::DOM::Exception',
			'$@ (after appendChild with wrong node type)';
		cmp_ok $@, '==',
			HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
			'appendChild with wrong node type throws a ' .
			'hierarchy error';
	}
	
	eval {
		appendChild{($elem->childNodes)[0]}$elem
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after appendChild with an ancestor node)';
	cmp_ok $@, '==', HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
	    'appendChild with an ancestor node throws a hierarchy error';

	my $other_elem = createElement $another_doc 'ddk';
	ok eval {
		$elem-> appendChild($other_elem);
	}, 'appendChild with wrong doc no longer dies';
	is $other_elem->ownerDocument, $elem->ownerDocument,
	 'appendChild with wrong doc sets the owner doc';

	my $dock = new HTML::DOM;
	ok eval{
	    $dock->appendChild(
		$dock->createComment('html'),undef
	    ); 1
	}, '$doc->appendChild doesn’t produce an invalid wrong doc error';
}

# -------------------------#
# Tests 77-8: hasChildNodes

$frag = createDocumentFragment $doc;

ok !hasChildNodes $frag, '!hasChildNodes';
$frag->appendChild(createTextNode $doc 'eoteuht');
ok  hasChildNodes $frag, 'hasChildNodes';

# -------------------------#
# Tests 79-91: cloneNode

use Scalar::Util 'refaddr';
{
	$frag->appendChild(my $clonee = $doc->createElement('div'));
	$clonee->appendChild(
		my $childelem = $doc->createElement('p'));
	$clonee->setAttribute('style' => 'color:black');
	$childelem->setAttribute('align' => 'left');
	my $attr = $clonee->getAttributeNode('style');
	my $childattr = $childelem->getAttributeNode('align');

	my $clone = cloneNode $clonee; # shallow

	cmp_ok $clonee, '!=', $clone, 'cloneNode makes a new object';
	cmp_ok +()=childNodes $clone, '==', 0,
		'shallow clone works';
	is_deeply [parentNode $clone], [], 'clones are orphans';
	cmp_ok +attributes $clone, '!=', attributes $clonee,
		'the attributes map is cloned during a shallow clone';
	cmp_ok refaddr $clone->getAttributeNode('style'), '!=',
	       refaddr $attr, 'attributes are cloned';
	
	$clone = cloneNode $clonee 1; # deep
	
	cmp_ok $clonee, '!=', $clone, 'deep cloneNode makes a new object';
	cmp_ok +(childNodes $clonee)[0], '!=', (childNodes $clone)[0],
		'deep clone works';
	is_deeply [parentNode $clone], [], 'deep clones are parentless';
	cmp_ok +attributes $clone, '!=', attributes $clonee,
		'the attributes map is cloned during a deep clone';
	cmp_ok refaddr $clone->getAttributeNode('style'), '!=',
	       refaddr $attr, 'deep clone clones attributes...';
	cmp_ok refaddr $clone->firstChild->getAttributeNode('align'), '!=',
	       refaddr $childattr, '...recursively';

	# Test that cloneNode sets the ownerDocument properly.
	# We have to set it up this way, as it’s only parser-generated ele-
	# ments that do not already explicitly reference their documents.
	# And then we have to do it twice, as the first clone sets it.
	my $div = $doc->createElement('div');
	$div->innerHTML("<input>");
	$clonee = $div->firstChild;
	is cloneNode $clonee->ownerDocument, $doc,
	 'shallow cloneNode sets the ownerDocument';
	$div->innerHTML("<input>");
	$clonee = $div->firstChild;
	is cloneNode $clonee 1=>->ownerDocument, $doc,
	 'deep cloneNode sets the ownerDocument';
}

# -------------------------#
# Tests 92-5: as_text and as_HTML

{
	my $element = $doc->createElement('p');
	$element->getAttribute('dir'); # make sure implied attributes don't
	                               # affect serialisation when accessed
	$element->appendChild($doc->createTextNode('This text contains '));
	$element->appendChild(my $belem = $doc->createElement('tt'));
	$belem->appendChild($doc->createTextNode('<tags>'));
	$element->appendChild($doc->createTextNode('.'));
	$element->appendChild($doc->createComment('<no comment>'));

	is $element->as_text, 'This text contains <tags>.', 'as_text';
	like $element->as_HTML,
	   qr\^<p>This text contains <tt>&lt;tags&gt;</tt>.(?x:
              )<!--<no comment>-->$\,
	   "as_HTML";

	# We forgot to pass the arguments to the superclass in releases
	# prior to 0.032.
	like $element->as_HTML((undef)x2,{}),
	     qr\^<p>This text contains <tt>&lt;tags&gt;</tt>.(?x:
	        )<!--<no comment>--></p>$\,
	   "as_HTML with args";
	$belem->tag('del');
	is $element->as_text(skip_dels => 1), "This text contains .",
	 'as_text with args';
}


# -------------------------#
# Tests 96-9: normalize

{
	my $element = $doc->createElement('p');
	$element->appendChild($doc->createTextNode(''));
	$element->appendChild($doc->createTextNode('This text is '));
	$element->appendChild($doc->createTextNode('made up of '));
	$element->appendChild($doc->createTextNode('three adjacent '));
	$element->appendChild($doc->createTextNode(''));
	$element->appendChild($doc->createTextNode('text nodes, if I '));
	$element->appendChild($doc->createTextNode('counted them '));
	$element->appendChild($doc->createTextNode('correctly.'));

	is +()=$element->normalize, 0, 'ret val of normal eyes';
	is $element->childNodes->length, 1,
		'number of text nodes after normal eyes ’ay shone';
	is $element->firstChild->data, 'This text is made up of three ' . 
	                              'adjacent text nodes, if I ' .
	                            'counted them correctly.',
		'resulting text after normalisation';

	$element->replaceChild($doc->createTextNode(''),
		$element->firstChild);
	$element->normalize;
	
	ok !$element->hasChildNodes,
		'normal eyes obliterate lone blank text nodes';
}

# -------------------------#
# Tests 100-2: XML namespace stuff

is +()=$frag->$_, 0, $_ for qw / namespaceURI prefix localName /;

# -------------------------#
# Tests 103-5: hasAttributes

ok !$frag->hasAttributes, 'hasAttributes (non-Element node)';
{
	my $elem = $doc->createElement('a');
	ok !$elem->hasAttributes, 'hasAttributes when an elem has none';
	$elem->attr('foo','bar');
	ok $elem->hasAttributes, 'hasAttributes returning true';
}

# -------------------------#
# Tests 106-7: isSupported

ok $frag->isSupported('hTML', '1.0'), 'isSupported';
ok!$frag->isSupported('onfun') ,'isn’tSupported';

# -------------------------#
# Test 108: push_content on an empty node

ok eval{$doc->createElement('foo')->push_content()},
	'push_content with no args on an empty node doesn\'t die';
	# broken in 0.012; fixed in 0.017

