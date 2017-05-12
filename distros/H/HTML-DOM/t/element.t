#!/usr/bin/perl -T

use strict; use warnings;

use Scalar::Util 'refaddr';
use lib 't';
use HTML::DOM;

# -------------------------#
use tests 2; # constructors

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

my $elem = $doc->createElement('a');
isa_ok $elem, 'HTML::DOM::Element';

$elem->attr('href' => 'about:blank');

# -------------------------#
use tests 4; # Node interface attributes

is nodeName $elem, 'A','nodeName';
cmp_ok $elem->nodeType, '==', HTML::DOM::Node::ELEMENT_NODE, 'nodeType';
is scalar(()=$elem->nodeValue), 0, 'nodeValue';
isa_ok +attributes $elem, 'HTML::DOM::NamedNodeMap';

# -------------------------#
use tests 1; # tagName

is tagName $elem, 'A', 'tagName';

# -------------------------#
use tests 1; # getAttribute

is $elem->getAttribute('href'), 'about:blank', 'getAttribute';

# -------------------------#
use tests 3; # setAttribute

is scalar(()=setAttribute $elem href=>'http://www.synodinresistance.org/'),
	0, 'setAttribute';
is $elem->getAttribute('href'),'http://www.synodinresistance.org/',
	'result of setAttribute';
setAttribute $elem pnin => [];
isa_ok $elem->getAttributeNode('pnin'), 'HTML::DOM::Attr',
 'retval of getAttributeNode after ref assignment to setAttribute';

# -------------------------#
use tests 3; # removeAttribute

is scalar(()=removeAttribute $elem 'href'),
	0, 'removeAttribute';
is $elem->getAttribute('href'),'',
	'result of removeAttribute';

$elem->setAttribute('href', bless[]);
ok eval{$elem->removeAttribute("href");1},
 'removeAttribute doesn\'t die when removing an object other than an attr';

$elem->attr('href' => 'about:blank'); # still need an attr with which to
                                      # experiment

# -------------------------#
use tests 4; # getAttributeNode


is scalar(()= getAttributeNode $elem 'aoeu'),
	0,'getAttributeNode returns null';
isa_ok+( my $attr = getAttributeNode $elem 'href'),
	'HTML::DOM::Attr';
is $attr->nodeName, 'href',
	'name of attr returned by getAttributeNode';
is $attr->nodeValue, 'about:blank',
	'value of attr returned by getAttributeNode';

# -------------------------#
use tests 10; # setAttributeNode

(my $new_attr = $doc->createAttribute('href'))
	->value('1.2.3.4');
is refaddr $elem->setAttributeNode($new_attr), refaddr $attr,
	'setAttributeNode returns the old node';
is $elem->getAttribute('href'), '1.2.3.4', 'result of setAttributeNode';

(my $another_attr = $doc->createAttribute('name'))->value('link');
is scalar(()=$elem->setAttributeNode($another_attr)), 0,
	'setAttributeNode can return null';
is $elem->getAttribute('name'), 'link', 'result of setAttributeNode (2)';

{
	my $other_doc = new HTML::DOM;
	my $attr = createAttribute $other_doc 'ddk';
	ok eval {
		$elem-> setAttributeNode(
			$attr
		);	
		1
	}, 'setAttributeNode with wrong doc no longer dies' ;
	is $attr->ownerDocument, $elem->ownerDocument,
	 'setAttributeNode with wrong doc sets the ownerDocument';
}

my $elem2 = $doc->createElement('a');
$elem2->setAttributeNode($attr);
is $elem2->getAttribute('href'), 'about:blank',
	'orphaned attribute nodes can be reused';

eval {
	$elem2-> setAttributeNode(
		$new_attr
	);
};
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after setAttributeNode with an attribute that is in use)';
cmp_ok $@, '==', HTML::DOM::Exception::INUSE_ATTRIBUTE_ERR,
    'setAttributeNode with an attribute that is in use throws the ' .
    'appropriate error';

$elem2->removeAttribute('href');
$elem2->setAttribute('href',bless[]);
ok eval{
	my $attr = $doc->createAttribute('href');
	$elem2->setAttributeNode($attr);
	1
}, 'setAttributeNode doesn\'t die when the attr is set to some random obj';

# -------------------------#
use tests 11; # removeAttributeNode

is refaddr $elem->removeAttributeNode($new_attr), refaddr $new_attr,
	'return value of removeAttributeNode';
is $elem->getAttribute('href'), '', 'result of removeAttributeNode';
{
	my $warn=0;
	local $SIG{__WARN__}  = sub{ ++$warn };

	eval {
		$elem->removeAttributeNode($doc->createAttribute('foo')),
	}
	;isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after removeAttributeNode with a non-existent attr)';
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_FOUND_ERR,
	    'removeAttributeNode with a non-existent attr throws the ' .
	    'appropriate error';
	is $warn, 0,
	    'removeAttributeNode with a non-existent attr doesn\'t warn';

	# The following two sets of tests differ  in  that,  in  the  first
	# case, the attribute we attempt to remove has not been accessed as
	# an  Attr  node yet,  while in the latter case  it  has.  (In  the
	# impl., we don’t bother with Attr nodes until explicitly requested
	# by the user  [the module’s user,  not the  script/app’s  user].)

	$warn = 0;
	$elem->attr(foo=>'bar');
	my $attr = $elem->removeAttributeNode(getAttributeNode$elem "foo");
	$elem->attr(foo=>'baz');
	eval {
		$elem->removeAttributeNode($attr),
	}
	;isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after failed remAttributeNode w/no auto-vivved attr)';
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_FOUND_ERR,
	    'failed remAttributeNode w/no auto-vivved attr throws the ' .
	    'appropriate error';
	is $warn, 0,
	    'failed remAttributeNode w/no auto-vivved attr doesn\'t warn';

	$warn = 0;
	$elem->attr(foo=>'bar');
	$attr = $elem->removeAttributeNode(getAttributeNode $elem "foo");
	$elem->attr(foo=>'baz');
	my $new_attr = $elem->getAttributeNode('foo');
	eval {
		$elem->removeAttributeNode($attr),
	}
	;isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after failed remAttributeNode w/auto-vivved attr)';
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_FOUND_ERR,
	    'failed remAttributeNode w/auto-vivved attr throws the ' .
	    'appropriate error';
	is $warn, 0,
	    'failed remAttributeNode w/auto-vivved attr doesn\'t warn';
}


# -------------------------#
use tests 8; # getElementsByTagName

{
	$doc->write('
		<div><!--sontoeutntont-->oentoeutn</div>
		<form>
			<div id=one>
				<div id=two>
					<div id=three>
						<b id=bi>aoeu></b>teotn
					</div>
				</div>
				<div id=four><i id=i></i>
				</div>
			</div>
		</form>
	');
	$doc ->close;

	my($elem) = $doc->getElementsByTagName('form');
	my($div_list, $node_list);

	my @ids = qw[ one two three four ];

	is_deeply [map id $_, getElementsByTagName $elem 'div'], \@ids,
		'getElementsByTagName(div) in list context';

	is_deeply [map id $_, @{
			$div_list = getElementsByTagName $elem 'div'
		}], \@ids,
		'getElementsByTagName(div) in scalar context';

	@ids = qw[ one two three bi four i ];

	is_deeply [map $_->id, getElementsByTagName $elem '*'],
		\@ids, 'getElementsByTagName(*) in list context';

	is_deeply [map $_->id, @{
			$node_list = getElementsByTagName$elem '*'
		}],
		\@ids, 'getElementsByTagName(*) in scalar context';

	# Now let's transmogrify it and make sure everything
	# updates properly.

	my($div1,$div2) = $elem->getElementsByTagName('div');
	$div1->removeChild($div2)->delete;

	is_deeply [map id $_, @$div_list], [qw[ one four ]],
		'div node list is updated';

	is_deeply [map $_->id || tag $_, @$node_list],
		[qw[ one four i ]], '* node list is updated';


	# Bug in 0.040 and earlier
	is $elem->getElementsByTagName('form')->length, 0,
	 'getEBTN looks only at the descendants, not the elem itself';
	is +()=$elem->getElementsByTagName('form'), 0,
	 'getEBTN (list cx) looks only @ descendants, not the elem itself';
}

# -------------------------#
use tests 4; # hasAttribute

{
	my $elem = $doc->createElement('a');
	$elem->attr('target','_blank');
	ok $elem->hasAttribute('tarGet'), 'hasAttribute';
	ok !$elem->hasAttribute('hrEf'), '!hasAttribute';
	ok $elem->hasAttribute('shApe'), 'hasAttribute (implied)';
	my $doc = new HTML::DOM;
	$doc->write('<!doctype html public "-//W3C//DTD HTML 4.01//EN"
			"http://www.w3.org/TR/html4/strict.dtd">');
	$doc->close;
	ok $doc->documentElement->hasAttribute('version'),
		'doc elem ->hasAttribute(version)';
}

# -------------------------#
use tests 25; # default attirbute values with getAttribute
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
		is $doc->createElement($$_[0])->getAttribute($$_[1]),
			$$_[2], "default value for @$_[0,1]";
	}

	my $doc = new HTML::DOM;
	$doc->write('
		<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
		<html><head>
		<title>404 Not Found</title>
		</head><body>
		<h1>Not Found</h1>
		<p>The requested URL /aoeu was not found on this server.
		   I\'ll try to look a little more closely next time.</p>
		</body></html>
	'); $doc->close;

	is $doc->documentElement->getAttribute('version'),
		'-//IETF//DTD HTML 2.0//EN',
		'implied version is taken from doctype (2)';

	$doc->write(q*
		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
			"http://www.w3.org/TR/html4/strict.dtd">
		
		<meta http-equiv=Content-Type
			content='text/html;charset=utf-8'>
		<link href=styles.css rel=stylesheet type='text/css'
			media=all>
		
		<title>Why do you want to see this?</title>
		
		<style>div{border: }</style>
		
		<!--bar-->
		<table cellspacing=0 style='width: 100%; height: 35px;
			 white-space: nowrap' class='tab textbrown'>
		<tr><td style='width: 300px; padding-right:5px'>
			<div> ... snip ...
			</div>
		... snip ...
		</table>
		... snip ...
	*); $doc->close;
	is $doc->documentElement->getAttribute('version'),
		'-//W3C//DTD HTML 4.01//EN',
		'implied version is taken from doctype (4.01)';

	$doc->write(q*
		<title>Back button experiment</title>

		<iframe style='height:0;width:0;visibility:hidden;
			margin:0;padding:0' src='iframe.html?1'
			id=_back_></iframe>
		<script>
			//snipped
		</script>
		<div id=content>This is page 1.</div>
		<a href='' onclick='
			go_to(+page+1);
			return false
		'>Next</a>
		<br><br>
	*); $doc->close;

	is $doc->documentElement->getAttribute('version'),
		'',
		'no implied version without doctype';
	is +()=$doc->documentElement->getAttributeNode('version'), 0,
		'getAttributeNode(version) in absence of doctype';

	my $elem = $doc->createElement('br');
	isa_ok $elem->getAttributeNode('clear'), 'HTML::DOM::Attr',
		'getAttributeNode on unspecified attribute';

	# These 2 tests make sure that the DTD values don’t override
	# explicit empty attributes:
	$elem = $doc->createElement('form');
	$elem->attr(enctype => '');
	is $elem->getAttribute('enctype'), '',
		'getAttribute on specified empty attribute';
	is $elem->getAttributeNode('enctype')->value, '',
		'getAttribteNode on specified empty attribute';
}
