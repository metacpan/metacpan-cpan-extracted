#!/usr/bin/perl -T

# This script contains a full test of the Node and EventTarget interfaces,
# since H:D:Attr implements them itself, and does not inherit
# from H:D:Node.

use strict; use warnings; use lib 't';

use Scalar::Util 'refaddr';
use HTML::DOM;

# -------------------------#
use tests 5; # constructors

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

my $elem = $doc->createElement('a');
isa_ok $elem, 'HTML::DOM::Element';

$elem->setAttribute(href => 'about:blank');

my $attr = $elem->getAttributeNode('href');
isa_ok $attr, 'HTML::DOM::Attr';
ok $attr->DOES('HTML::DOM::Node'), '$attr does HTML::DOM::Node';
isa_ok $attr, 'HTML::DOM::EventTarget', '$attr';


# -------------------------#
use tests 1; # overloading

is $attr, 'about:blank', '""';

# -------------------------#
use tests 1; # name

is name $attr, 'href', 'name';


# -------------------------#
use tests 41; # specified

{
	for(
		[qw[ br clear none ]],
		[qw[ td colspan 1 ]],
		[qw[ th colspan 1 ]],
		[qw[ form enctype application/x-www-form-urlencoded ]],
		[qw[ frame frameborder 1 ]],
		[qw[ iframe frameborder 1 ]],
		[qw[ form method GET ]],
		[qw[ td rowspan 1 ]],
		[qw[ th rowspan 1 ]],
		[qw[ frame scrolling auto ]],
		[qw[ iframe scrolling auto ]],
		[qw[ area shape rect ]],
		[qw[ a shape rect ]],
		[qw[ col span 1 ]],
		[qw[ colgroup span 1 ]],
		[qw[ input type TEXT ]],
		[qw[ button type submit ]],
		[qw[ param valuetype DATA ]],
	) {
		my $elem = $doc->createElement($$_[0]);
		my $attr = $elem->getAttributeNode($$_[1]);
		ok !$attr->specified, "@$_[0,1] !specified";
		is $attr->value, $$_[2], "default value of @$_[0,1]";
	}
	my $doc = new HTML::DOM;
	$doc->write('
		<!DOCTYPE HTML PUBLIC
			"-//W3C//DTD HTML 4.01 Transitional//EN">
		<title></title>
	');$doc->close;
	ok !specified{$doc->documentElement->getAttributeNode('version')},
		"html version !specified";
	is $doc->documentElement->getAttributeNode('version')->value,
		'-//W3C//DTD HTML 4.01 Transitional//EN',
		"default value of html version";

	my $elem = $doc->createElement('br');
	ok specified{
		removeAttributeNode$elem getAttributeNode$elem 'clear'
	}, "specified after removal";
	$elem->attr('clear','left');
	ok specified{getAttributeNode$elem 'clear'},
		'specified when explicit';
	$elem->attr('clear','none');
	ok specified{getAttributeNode$elem 'clear'},
		'specified when explicit, even when eq default';
}

# -------------------------#
use tests 3; # value

is value $attr, 'about:blank', 'get value';
is $attr->value('javascript:window.close()'), 'about:blank',
	'return value of setting the value is the old value';
is $elem->getAttribute('href'), 'javascript:window.close()',
	'setting the value works';

# -------------------------#
use tests 15; # Node interface attributes

# HTML::DOM::Attr implements all the Node interface itself, and does not
# inherit from HTML::DOM::Node.

is nodeName $attr, 'href', 'nodeName';
is nodeValue $attr, 'javascript:window.close()', 'nodeValue';
cmp_ok nodeType $attr, '==', HTML::DOM::Node::ATTRIBUTE_NODE, 'nodeType';
is_deeply[parentNode$attr],[],'parentNode';

my $children = childNodes $attr;
my @children = childNodes $attr; # list context
is $children->length, 1, 'number of child nodes';
is scalar @children, 1, 'number of child nodes (list context)';
isa_ok my $text_node = $children->[0], 'HTML::DOM::Text', 'child node';
&cmp_ok(@children, '==', $text_node,
	'(childNodes $attr)[0] is the same as childNodes $attr ->[0]');
is $text_node->data, 'javascript:window.close()',
	'data contained by child node';

cmp_ok firstChild $attr, '==', $text_node, 'firstChild';
cmp_ok  lastChild $attr, '==', $text_node,  'lastChild';
is_deeply[previousSibling$attr],[],'previousSibling';
is_deeply[    nextSibling$attr],[],    'nextSibling';
is_deeply[attributes$attr],[],'attributes';
cmp_ok  ownerDocument $attr, '==', $doc,  'ownerDocument';


# -------------------------#
use tests 26; # Node interface methods

eval { insertBefore $attr };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after insertBefore)';
cmp_ok $@, '==', 
	HTML::DOM::Exception::NO_MODIFICATION_ALLOWED_ERR,
	'insertBefore throws a "no modification allowed" error';

{ # replaceChild
	$elem->appendChild(my $new_text =
		createTextNode $doc 'http://www.perl.org/');
	cmp_ok $text_node, '==', $attr->replaceChild(
			$new_text, $text_node
		), 'replaceChild returns the replaced node';
	is scalar(()=childNodes$elem), 0,
		'replaceChild removes from the tree first';

	my $frag = createDocumentFragment $doc;

	eval { $attr->replaceChild($frag, $new_text); };
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after replaceChild with a frag that does not have ' .
		'exactly one child node)';
	cmp_ok $@, '==',
		HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
		'replaceChild with with a frag that does not have ' .
		'exactly one child node throws a ' .
		'hierarchy error';	

	$frag->appendChild(createTextNode $doc 'lalala');
	$attr->replaceChild($frag, $new_text);
	is $attr->value, 'lalala',
		'replaceChild(frag,node) inserts the frag\'s children';

	eval {
		$attr->replaceChild(
			(createAttribute $doc 'ddk'), $attr->firstChild
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after replaceChild with wrong node type)';
	cmp_ok $@, '==',
		HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
		'replaceChild with wrong node type throws a ' .
		'hierarchy error';
	
	appendChild $frag createElement $doc 'div';
	eval { $attr->replaceChild($frag, firstChild $attr); };
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after replaceChild with a frag containing the wrong' .
		' node type)';
	cmp_ok $@, '==',
		HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
		'replaceChild with a frag containing the wrong' .
		' node type throws a ' .
		'hierarchy error';

	my $another_doc = new HTML::DOM;
	my $another_node = createTextNode $another_doc 'ddk';
	ok eval {
		$attr->replaceChild(
			$another_node,
			(childNodes $attr)[0],
		);
		1
	}, 'replaceChild with wrong doc no longer dies';
	is $another_node->ownerDocument, $doc,
		'replaceChild with wrong doc changes the owner doc';

	eval {
		$attr-> replaceChild(
			$doc->createTextNode('ddk'), $text_node
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after replaceChild with a bad refChild)';
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_FOUND_ERR,
		'replaceChild with a 2nd arg that\'s not a child of ' .
		'this node throws a "not found" error';
}

eval { removeChild $attr };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after removeChild)';
cmp_ok $@, '==', 
	HTML::DOM::Exception::NO_MODIFICATION_ALLOWED_ERR,
	'removeChild throws a "no modification allowed" error';

eval { appendChild $attr };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after appendChild)';
cmp_ok $@, '==', 
	HTML::DOM::Exception::NO_MODIFICATION_ALLOWED_ERR,
	'appendChild throws a "no modification allowed" error';

ok hasChildNodes $attr, 'hasChildNodes';

my $clone = cloneNode $attr; # shallow

cmp_ok refaddr $attr, '!=', refaddr $clone, 'cloneNode makes a new object';
cmp_ok +(childNodes $attr)[0], '!=', (childNodes $clone)[0],
	'shallow clone works ignores its deep arg';
is_deeply [parentNode $clone], [], 'clones are orphans';

$clone = cloneNode $attr 1; # deep

cmp_ok refaddr $attr, '!=', refaddr $clone,
	'deep cloneNode makes a new object';
cmp_ok +(childNodes $attr)[0], '!=', (childNodes $clone)[0],
	'deep clone works';
is_deeply [parentNode $clone], [], 'deep clones are parentless';


# -------------------------#
use tests 4; # ownerElement

{
	my $elem = $doc->createElement('a');
	my $attr = $doc->createAttribute('href');
	$elem->setAttributeNode($attr);
	is $attr->ownerElement, $elem,
		'ownerElement after setAttributeNode';

	my $nother_attr = $doc->createAttribute('href');
	$elem->setAttributeNode($nother_attr);
	is +()=$attr->ownerElement, 0,
		'ownerElement after setAttributeNode replaces it';

	$elem->removeAttributeNode($nother_attr);
	is $nother_attr->ownerElement, undef,
		'removeAttributeNode updates ownerElement';

	$elem->setAttribute('target', '_blank');
	is $elem->getAttributeNode('target')->ownerElement, $elem,
		'ownerElement of autovivified attr';

}

# -------------------------#
use tests 4; # XML namespace stuff and normal eyes

is +()=$attr->$_, 0, $_ for qw / namespaceURI prefix localName normalize /;


# -------------------------#
use tests 1; # hasAttributes

ok !$attr->hasAttributes, 'hasAttrbitues';

# -------------------------#
use tests 2; # booleanness

{
	my $attr = $doc->createAttribute('foo');
	ok !"$attr",
	    'make sure our booleanness test is actually doing something';
	ok $attr, 'boooleannness';
}

# -------------------------#
use tests 2; # isSupported

ok $attr->isSupported('hTML', '1.0'), 'isSupported';
ok!$attr->isSupported('onfun') ,'isn’tSupported';

# -------------------------#
use tests 2; # relationship to the child text node (bug fixed in 0.017)
{
	is refaddr $attr->firstChild->parentNode, refaddr $attr,
	  "an attr's text node's parent is the attr after replaceChild";
	$attr = $doc->createAttribute('foo');
	is refaddr $attr->firstChild->parentNode, refaddr $attr,
		"a new attr's text node's parent is the attr";
}
