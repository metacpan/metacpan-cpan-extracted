#!/usr/bin/perl

use strict; use warnings; use lib 't';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use HTML::DOM;
my $doc = new HTML::DOM;

# -------------------------------- #
use tests 17; # ElementCSSInlineStyle

{
	(my $elem = $doc->createElement('div'))
		->setAttribute('style', 'margin-top: 3px');
	isa_ok($elem->style, 'CSS::DOM::Style');
	is $elem->style->marginTop, '3px',
		'the css dom is copied from the style attribute';
	$elem->style->marginTop('4em');
	is $elem->getAttribute('style'), 'margin-top: 4em',
		'modifications to the css dom are reflected in the attr';
	$elem->setAttribute('style', 'margin-bottom: 2px');
	is $elem->style->marginBottom(), '2px',
		'Subsequent changes to the attr change the dom,';
	is $elem->style->marginTop, '', 'even deleting properties.';

	$elem->removeAttribute('style');
	like $elem->style->cssText, qr/^\s*\z/,
		'removeAttribute erases the css data';

	$elem->style->paddingTop('3in');
	is $elem->getAttributeNode('style')->value, 'padding-top: 3in',
		'getAttributeNode reads the CSS data';
	my $attr = $doc->createAttribute('style');
	$attr->value('padding-top: 4cm');
	$elem->setAttributeNode($attr);
	is $elem->style->paddingTop,'4cm',
		'setAttributeNode sets the CSS data';
		# (Actually, it deletes it, but that’s merely an implemen-
		#  tation detail.)

	$elem->removeAttributeNode($elem->getAttributeNode('style'));
	like $elem->style->cssText, qr/^\s*\z/,
		'removeAttributeNode erases the css data';

	$elem->setAttribute('style' => '');
	$attr = $elem->getAttributeNode('style');
	(my $style = $elem->style)->marginTop('30px');
	is $attr->value, 'margin-top: 30px',
		'changes to the style obj are reflected in the attr node';
	is $elem->style, $style,
		'without the style object getting clobbered';
	$attr->value('color:red');
	is $elem->style->cssText, 'color: red',
		'changes to the attr node are reflected in the style obj';
	$attr->firstChild->data('hand-color:red');
	is $elem->style->cssText, 'hand-color: red',
	   'changes to the attr\'s child text node change the style obj';
	
	$elem->removeAttribute('style');
	$elem->setAttribute('style', 'color:red');
	$attr = $elem->getAttributeNode('style');
	$elem->style->color('blue');
	is $attr->value, 'color: blue',
	   'style mods change the attr when attr was auto-vivved B4 style';
	
	my $new_attr = $doc->createAttribute('style');
	$new_attr->value( "foo:bar");
	$elem->setAttributeNode($new_attr);
	is $elem->style->cssText, 'foo: bar',
		'replacing the attr node clobbers the style obj';

	$elem->removeAttribute('style');
	$elem->setAttribute('style','color:red');
	$attr = $elem->getAttributeNode('style');
	$attr->style # auto-viv
	   ->color('green');
	is $attr->firstChild # auto-viv
	    ->data, 'color: green',
	 "an attr's text node auto-vivved after the style obj is in synch";

	is $elem->getAttribute('style'), 'color: green',
		'style attr nodes stringify properly';
}

# -------------------------------- #
use tests 10; # LinkStyle

{
	(my $elem = $doc->createElement('style'))->appendChild(
		$doc->createTextNode('a { color: black}')
	);
	isa_ok $elem->sheet, 'CSS::DOM', '<style> ->sheet';
	is +($elem->sheet->cssRules)[0]->selectorText, 'a',
		'contents are there';

	my $doc = new HTML::DOM;
	my $css ;
	$doc->css_url_fetcher(sub{$css});
	$doc->write("<link href='data:text/css,'>");
	$doc->write("<link rel=stylesheet href='data:text/css,'>");
	$doc->close;
	my @links = $doc->find('link');
	is +()=$links[0]->sheet, 0,
	 'sheet returns null when rel != stylesheet';
	is +()=$links[1]->sheet, 0,
	 'sheet returns null when rel == stylesheet, & cuf returns undef';

	$css='';
	$doc->write("<link href='data:text/css,'>");
	$doc->write("<link rel=stylesheet href='data:text/css,'>");
	$doc->close;
	@links = $doc->find('link');
	is +()=$links[0]->sheet, 0,
	 'sheet returns null when rel != stylesheet, even w/cuf';
	isa_ok $links[1]->sheet, 'CSS::DOM',
	 '<link> ->sheet when rel == stylesheet and cuf returns defined';

	$css='a{color:green}';
	$links[1]->setAttribute('href', 'dware');
	is $links[1]->sheet->cssRules->length, 1,
	 'setting the href attribute updates the sheet';
	$css='a{color:green}p{text-align:center}';
	$links[1]->getAttributeNode('href')->firstChild->data('cring');
	is $links[1]->sheet->cssRules->length, 2,
	 'modifying the href attribute node updates the sheet';

	my $cuf = $doc->css_url_fetcher;
	$css='ceck';
	is &$cuf, 'ceck',
	 'css_url_fetcher returns the previous assigned sub';
	is $doc->css_url_fetcher(sub{}), $cuf,
	 'css_url_fetcher returns the old value on assignment';
}

# -------------------------------- #
use tests 17; # DocumentStyle

{
	use Scalar::Util 'refaddr';

	my $doc = new HTML::DOM;
	$doc->css_url_fetcher(sub{''});
	$doc->write('
		<style id=stile>b { font-weight: bold }</style>
		<link id=foo rel=stylesheet>
		<link rel=bar>
	');
	$doc->close;

	isa_ok my $list = $doc->styleSheets, 'CSS::DOM::StyleSheetList',
		'retval of styleSheets';
	is $list->length, 2, 'sheet list doesn\'t include <link rel=bar>';
	is my @list = $doc->styleSheets, 2, 'styleSheets in list context';
	
	is refaddr $list->[0], refaddr $list[0],
		'both retvals have the same first item';
	is refaddr $list->[1], refaddr $list[1],
		'both retvals have the same second item';
	is refaddr $list[0], refaddr $doc->getElementById('stile')->sheet,
		'the style elem\'s sheet is in the list';
	is refaddr $list[1],
	   refaddr +(my $link = $doc->getElementById('foo'))->sheet,
		'the link elem\'s sheet is in the list';


	# $list should update automatically, since it is a reference to the
	# doc’s own style sheet list.
	# @list is static.

	$link->setAttribute(rel => "a nice big\xa0stylesheet\nhere");
	is refaddr $list->[1], refaddr $list[1],
	    'setAttribute w/o changing whether rel contains "stylesheet"';

	$link->setAttribute(rel => 'contents');
	is @$list, 1,
	    'setAttribute(rel => contents) deletes the style sheet obj';

	$link->setAttribute(rel => 'a stylesheet');
	is @$list, 2,
	    'setAttribute adds the style sheet to the list';
	SKIP: { skip 'What is the correct behaviour?' ,1;
	isn't refaddr $list->[1], refaddr $list[1],
	    'creating it from scratch';
	}

	@list = @$list;

	(my $attr = $doc->createAttribute('rel'))->nodeValue('stylesheEt');
	$link->setAttributeNode($attr);
	is refaddr $list[1], refaddr $list->[1],
	    'setAttributeNode w/o changing whether rel =~ "stylesheet"';

	(my $attr2 = $doc->createAttribute('rel'))->nodeValue('contents');
	$link->setAttributeNode($attr2);
	is @$list, 1,
	    'setAttributeNode(contents) deletes the style sheet obj';

	$link->setAttributeNode($attr);
	is @$list, 2,
	    'setAttributeNode adds the style sheet to the list ...';
	SKIP: { skip 'What is the correct behaviour?' ,1;
	isn't refaddr $list->[1], refaddr $list[1],
	    '... creating it from scratch';
	}
	
	$link->removeAttribute('rel');
	is @$list, 1, 'removeAttribute removes the style sheet';

	$link->setAttribute(rel => 'stylesheet');
	$link->removeAttributeNode($link->getAttributeNode('rel'));
	is @$list, 1, 'removeAttributeNode removes the style sheet';
}

# -------------------------------- #
use tests 23; # ViewCSS

{
	package TestView;
	require HTML'DOM'View;
	our @ISA = HTML::DOM::View::;
	sub new { bless [], shift }
	sub ua_style_sheet { return $_[0][0] }
	sub user_style_sheet { return $_[0][1] }

	package main;
	my $doc = new HTML::DOM;
	(my $view = new TestView) -> document ( $doc );

	require CSS::DOM;
	VERSION CSS'DOM 0.07;
	$view->[0] = CSS'DOM'parse(' /* UA style sheet */
		#twelve { font-size: 13px }
		#thirteen { font-size: 14px }
		#fourteen { font-size: 15px
	');
	$view->[1] = CSS'DOM'parse(' /* User style sheet */
		#twelve { font-size: 3px }
		#thirteen { font-size: 4px }
	');
	
	$doc->write(<<'_END_');
<!-- Pilfered from http://www.w3.org/Style/CSS/Test/CSS2.1/current/html4/
     t060401-c32-cascading-00-b.htm with some modifications. -->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<html>
 <head>
 <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
  <title>CSS Test: Cascading Order</title>
  <link rel="author" href="http://www.w3.org/Style/CSS/Test/CSS1/current/tsack.html" title="CSS1 Test Suite Contributors">
  <link rel="author" href="censored in case someone is scraping this" title="Ian Hickson">
  <link rel="stylesheet" href="support/c-red.css">
  <style type="text/css">
   body * { color: red; list-style: none; margin: 0; padding: 0; }
   span { color: red; }
   li span.a { color: red; }
   li span.b { color: red; }
   li span.c { color: red; }
   li span.d { color: red; }
   li span.e { color: red; }
   li span.f { color: red; }
   ul li span.a { color: green; }
   ul li span.b { color: green; }
   ul li li span.c { color: red; }
   ul li li span.d { color: red; }
   ul li li span.e { color: red; }
   ul li li span.f { color: red; }
   ul li li span.c { color: green; }
   li.test1 span.d { color: green; }
   ul li.test2 span.e { color: green; }
   ul li.test3 span.f { color: red; }
   ul li#test3 span.f { color: green; }
   .test4 { color: red; }
   .test4 { color: green; }
   .c { color: green; }
  #twelve { font-size: 5px }
  </style>
  <link rel="help" href="http://www.w3.org/TR/CSS21/cascade.html#cascading-order" title="6.4.1 Cascading order">
  <link rel="help" href="http://www.w3.org/TR/CSS21/cascade.html#specificity" title="6.4.3 Calculating a selector's specificity">
 </head>
 <body>
  <ul>
   <li> <span class="a" id=one> This should be green. </span> </li>
   <li> <span class="b" id=two> This should be green. </span>
    <ul>
     <li> <span class="c" id=three> This should be green. </span> </li>
     <li> <span class="c" id=four> This should be green. </span> </li>
     <li class="test1"> <span class="d" id=five> This should be green. </span> </li>
    </ul>
   </li>
   <li class="test2"> <span class="e" id=six> This should be green. </span> </li>
   <li id="test3" class="test3"> <span class="f" id=seven> This should be green. </span> </li>
   <li> <span class="a" id=eight> This should be green. </span> </li>
  </ul>
  <p style="color: green;" id=nine> This should be green. </p>
  <p class="test4" id=ten> This should be green. </p>
  <p class="c" id=eleven> This should be green. </p>
  <span id=twelve></span><span id=thirteen></span><span id=fourteen></span>
 </body>
</html>
_END_
	$doc->close;

#warn $view->getComputedStyle($doc->getElementById('one'))->cssText;
#exit;

	my $green = qr/^(?:green|#0(?:0ff0|f)0|rgb\(0%?\s*,\s*(?:100%|255)\s*,\s*0%?\))\z/i;

	like $view->getComputedStyle($doc->getElementById($_))->color,
		$green,
		"cascade test $_ from t060401-c32-cascading-00-b.htm"
		for qw/ one two three four five six seven eight nine ten
		        eleven /;
	is $view->getComputedStyle($doc->getElementById('twelve'))
		->fontSize, '5px', 'author overrides user and ua';
	is $view->getComputedStyle($doc->getElementById('thirteen'))
		->fontSize, '4px', 'user overrides ua';
	is $view->getComputedStyle($doc->getElementById('fourteen'))
		->fontSize, '15px', 'fallback to ua';

	

	$view->[0]=CSS'DOM'parse(' /* UA style sheet */
		p { color: yellow ! important; }
		span { font-size: 38px !important }
	');
	$view->[1]=CSS'DOM'parse(' /* User style sheet */
		a { font-size: 14px ! important }
	');
	$doc->write(<<'_TEMDOBEDXK>N');
<!-- Modified version of http://www.w3.org/Style/CSS/Test/CSS2.1/current/
     html4/t060402-c31-important-00-b.htm -->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<html>
 <head>
 <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
  <title>CSS Test: important</title>
  <link rel="author" href="http://www.w3.org/Style/CSS/Test/CSS1/current/tsack.html" title="CSS1 Test Suite Contributors">
  <link rel="author" href="mailto:ian at some server called hixie.ch" title="Ian Hickson">
  <style type="text/css">
   p { color: green ! important; }
   p { color: red; }
   p#id1 { color: red; }
   a { font-size: 1px !important }
   span { font-size: 23px }
   div { text-transform: none }
   div:first-line { text-transform: uppercase }
  </style>
  <link rel="help" href="http://www.w3.org/TR/CSS21/cascade.html#important-rules" title="6.4.2 !important rules">
  <link rel="help" href="http://www.w3.org/TR/CSS21/cascade.html#cascading-order" title="6.4.1 Cascading order">
 </head>
 <body>
  <p> This line should be green. </p>
  <p id="id1"> This line should be green. </p>
  <p style="color: red;"> This line should be green. </p>
  <a href=""></a><span id=s></span>
  <div></div>
 </body>
</html>
_TEMDOBEDXK>N
	$doc->close;

	my $ps = $doc->getElementsByTagName('p');
	like $view->getComputedStyle($ps->[0])->color, $green,
	 '!important overrides following rule with same specificiciciicty'
	 . '(and also overrides an !important ua rule)';
	like $view->getComputedStyle($ps->[1])->color, $green,
	 '!important overrides following rule w/higher specificiciciicty';
	like $view->getComputedStyle($ps->[2])->color, $green,
	 '!important overrides style attr';
	is $view->getComputedStyle($doc->links->[0])->fontSize, '14px',
		'user !important overrides author !important';
	is $view->getComputedStyle($doc->getElementById('s'))->fontSize,
		'38px',
		'!important ua decl overrides un!important author decl';
	my $d = $doc->getElementsByTagName('div')->[0];
	is $view->getComputedStyle($d)->textTransform, 'none',
		'getComputedStyle without pseudo-elem';
	# Opera 9.2 only supports this:
	is $view->getComputedStyle($d, 'first-line')->textTransform,
		'uppercase', 'getComputedStyle with colonless pseudo-elem';
	# FF 3 only supports these two:
	is $view->getComputedStyle($d, ':first-line')->textTransform,
		'uppercase', 'getComputedStyle with monocolic pseudo-elem';
	is $view->getComputedStyle($d, '::first-line')->textTransform,
		'uppercase', 'getComputedStyle with dyocolic pseudo-elem';

	# ~~~ computed values
	# ~~~ immutability
}

