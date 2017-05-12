#!/usr/bin/perl -T

# This script tests the HTMLElement interface and most of the interfaces
# that are derived from it (not forms or tables).

# Note: Some attributes are supposed to have their values normalised when
# accessed through the DOM 0 interface. For this reason, some attributes,
# particularly ‘align’, have weird capitalisations of their values when
# they are set. This is intentional.

use strict; use warnings;

use lib 't';
use HTML::DOM;
use Scalar::Util 1.09 'refaddr';
use tests();

sub test_attr {
	my ($obj, $attr, $val, $new_val) = @_;
	my $attr_name = (ref($obj) =~ /[^:]+\z/g)[0] . "'s $attr";

	# I get the attribute first before setting it, because at one point
	# I had it setting it to undef with no arg.
	is $obj->$attr,          $val,     "get $attr_name";
	is $obj->$attr($new_val),$val, "set/get $attr_name";
	is $obj->$attr,$new_val,     ,     "get $attr_name again";
}

# A useful value for testing boolean attributes:
{package false; use overload 'bool' => sub {0}, '""'=>sub{"oenuueo"};}
my $false = bless [], 'false';

# -------------------------#
use tests 1; # document constructor

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

{
	my ($evt,$targ);
	my $eh = sub{
		($evt,$targ) = ($_[0]->type, shift->target);
	};
	
	sub test_event {
		my($obj, $event) = @_;
		($evt,$targ) = ();
		my $class = (ref($obj) =~ /[^:]+\z/g)[0];
		$obj->addEventListener($event=>$eh);
		is_deeply [$obj->$event], [],
			"return value of $class\'s $event method";
		is $evt, $event, "$class\'s $event method";
		is refaddr $targ, refaddr $obj, 
			"$class\'s $event event is on target";
		$obj->removeEventListener($eh);
	}
}
	


# -------------------------#
use tests 82; # Element types that just use the HTMLElement interface
              # (and general tests for that interface)

for (qw/ sub sup span bdo tt i b u s strike big small em strong dfn code
         samp kbd var cite acronym abbr dd dt noframes noscript
         address center /) {
	is ref $doc->createElement($_), 'HTML::DOM::Element',
		"class for $_";
}

{
	my $elem = $doc->createElement('sub');
	$elem->attr(id => 'di');
	$elem->attr(title => 'eltit');
	$elem->attr(lang => 'en');
	$elem->attr(dir => 'lefT');
	$elem->attr(class => 'ssalc');

	test_attr $elem, qw/ id        di    eyeD /;
	test_attr $elem, qw/ title     eltit titulus /;
	test_attr $elem, qw/ lang      en    el /;
	test_attr $elem, qw/ dir       left  right /;
	is $elem->className,'ssalc',               ,     'get className';
	is $elem->className('taxis'),       'ssalc', 'set/get className';
	is $elem->className,'taxis',               , 'get className again';

	test_event $elem => $_ for qw/click/;
	my $thing;
	$elem->addEventListener(click => sub { $thing.='click' });
	$elem->addEventListener(DOMActivate => sub { $thing.='activate' });
	$elem->click();
	is $thing, 'clickactivate', 'click triggers DOMActivate';

	
	(my$subelem= $doc->createElement("a"))->setAttribute("foo"=>"bar");
	$subelem->appendChild($_) for
		$doc->createTextNode('baz'),
		$doc->createElement('br'),
		$doc->createTextNode('teette');
	$elem = $doc->createElement('div');
	$elem->push_content($subelem);
	$elem->push_content($doc->createTextNode("tehdob"));
	like $elem->innerHTML, qr/^
		<(?i:a\s*foo)\s*=\s*(['"]?)bar\1\s*>
			baz
			<(?i:br)\s*>
			teette
		<\/[aA]\s*>
		tehdob
	\z/x, 'innerHTML serialisation';

	my $html = $elem->innerHTML;
	is $elem->innerHTML('<div><p>foo<b>bar</b></div>'), $html,
		'return value of innerHTML with argument';
	like $elem->innerHTML, qr'^<div><p>foo<b>bar</b>(?:</p>)?</div>\z',
		'result of setting innerHTML';
	$elem->innerHTML('<body><head><br></html>'); # :-)
	is $elem->innerHTML,'<br>', 'innerHTML(mangled stuff)';

	$elem->innerHTML('');
	is $elem->childNodes->length, 0, 'innerHTML("")';

	ok eval{$elem->innerHTML('<a onclick="">');1},
		'innerHTML doesn\'t die when fed an event attribute';

	# Test for what I consider a bug in HTML::TreeBuilder, but which
	# others may not consider so....
	$elem->innerHTML('<p></p><table><tr><td></table>');
	$elem->innerHTML($elem->innerHTML);
	is $elem->find('p')->childNodes->length, 0, 'innerHTML round-trip';

	# Make sure that !doctypes are ignored in innerHTML
	$doc->open; $doc->close;
	$doc->body->innerHTML('
		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
			"http://www.w3.org/TR/html4/strict.dtd">
	');
	unlike $doc->innerHTML, qr/doctype/i,
	 'innerHTML’s parser ignores !doctypes';

	# Make sure that innerHTML resets node lists
	$elem->innerHTML("");
	my $list = $elem->getElementsByTagName('br');
	$list->length; # cache the contents
	$elem->innerHTML("<br>");
	is scalar @$list, 1, 'innerHTML resets node lists';

	# Yes, the weird capitalisation is on purpose. I forgot the ‘lc’
	# in these insertAdj* routines at first.
	$elem->innerHTML('<b></b>');
	$elem->firstChild->insertAdjacentHTML('bEforebegin','<i></i>');
	is $elem->innerHTML, '<i></i><b></b>',
	 'insertAdjacentHTML beforebegin';
	$elem->firstChild->insertAdjacentHTML('aFterend','<u></u>');
	is $elem->innerHTML, '<i></i><u></u><b></b>',
	 'insertAdjacentHTML afterend';
	$elem->insertAdjacentHTML('aftErbegin','<tt></tt>');
	is $elem->innerHTML, '<tt></tt><i></i><u></u><b></b>',
	 'insertAdjacentHTML afterbegin';
	$elem->insertAdjacentHTML('befOreend','prext');
	is $elem->innerHTML, '<tt></tt><i></i><u></u><b></b>prext',
	 'insertAdjacentHTML beforeend';

	# Make sure that insertAdjacentHTML resets node lists
	$elem->innerHTML("");
	$list = $elem->getElementsByTagName('br');
	$list->length; # cache the contents
	$elem->insertAdjacentHTML(afterbegin=>"<br>");
	is scalar @$list, 1, 'insertAdjacentHTML resets node lists';

	$elem->innerHTML('<b></b>');
	$elem->firstChild->insertAdjacentElement(
	 'beForebegin',$doc->createElement('i')
	);
	is $elem->innerHTML, '<i></i><b></b>',
	 'insertAdjacentElement beforebegin';
	$elem->firstChild->insertAdjacentElement(
	 'afTerend',$doc->createElement('u')
	);
	is $elem->innerHTML, '<i></i><u></u><b></b>',
	 'insertAdjacentElement afterend';
	$elem->insertAdjacentElement(
	 'afterbegiN',$doc->createElement('tt')
	);
	is $elem->innerHTML, '<tt></tt><i></i><u></u><b></b>',
	 'insertAdjacentElement afterbegin';
	$elem->insertAdjacentElement(
	 'beforeenD',$doc->createTextNode('pred')
	);
	is $elem->innerHTML, '<tt></tt><i></i><u></u><b></b>pred',
	 'insertAdjacentElement beforeend';

	# Make sure that insertAdjacentElement resets node lists
	$elem->innerHTML("");
	$list = $elem->getElementsByTagName('br');
	$list->length; # cache the contents
	$elem->insertAdjacentElement(afterbegin=>createElement $doc 'br');
	is scalar @$list, 1, 'insertAdjacentElement resets node lists';

	$elem->innerHTML(
	 "<p>This is a&#32;sentence w/<b>bold <i>and</i></b><i> italics."
	);
	is $elem->innerText, 'This is a sentence w/bold and italics.',
	 'innerText retval';
	is $elem->innerText("<frow>"),
	  "This is a sentence w/bold and italics.",
	  'retval of innerText when setting';
	is $elem->innerText, "<frow>",
	 'setting innerText';
	is $elem->innerHTML, "&lt;frow&gt;",
	 'setting innerText does not create HTML elems';
	 # This is also a test for innerHTML, too, which would return lit-
	 # eral angle brackets for text nodes that were direct children of
	 # the element.

	{ package oVerload;
		use overload '""' => sub {${+shift}}, fallback => 1;
	 }
	$elem->innerHTML('
	  <p id="p1" class="aaa bbb">
	  <p id="p2" class="aaa ccc">
	  <p id="p3" class="bbb ccc">
	');
	is_deeply [map id $_, getElementsByClassName $elem 'aaa'],
		['p1', 'p2'],
		'getElementsByClassName';
	is_deeply
	  [
	   map id $_, getElementsByClassName $elem
	                             bless \do{my $v = 'aaa'}, 'oVerload'
	  ],
	  ['p1', 'p2'],
	 'getElementsByClassName stringfication';
	is_deeply
	  [map id $_, @{
	   getElementsByClassName $elem
	    bless \do{my $v = 'aaa'}, 'oVerload'
	  }],
	  ['p1', 'p2'],
	 'getElementsByClassName stringfication in scalar context';
	is_deeply
	  [map id $_, getElementsByClassName $elem 'ccc bbb'],
	  ['p3'],
	 'getElementsByClassName with multiple classes';
	is getElementsByClassName $elem 'aaa,bbb'=>->length, 0,
	 'getElementsByClassName("aaa,bbb")';
	
	# More tests, not based on HTML 5.

	$elem->innerHTML('
	  <div id=commas class="aaa,bbb"></div>
	  <div id=hyphen class="aaa-bbb"></div>
	  <div id=vertab class="&#11;"></div>
	');
	@_ = getElementsByClassName $elem "aaa";
	is @_, 0,
	  'getElementsByClassName does not treat hyphen or comma as bound';
	@_ = getElementsByClassName $elem "aaa,bbb";
	is @_, 1, 'successful getElementsByClassName with comma (count)';
	is $_[0]->id, 'commas',
          'successful getElementsByClassName with comma (which elem)';
	@_ = getElementsByClassName $elem "aaa-bbb";
	is @_, 1, 'successful getElementsByClassName with hyphen (count)';
	is $_[0]->id, 'hyphen',
          'successful getElementsByClassName with hyphen (which elem)';
	@_ = getElementsByClassName $elem "\ck";
	is @_, 1, 'successful getElementsByClassName with vtab (count)';
	is $_[0]->id, 'vertab',
          'successful getElementsByClassName with vtab (which elem)';


}

# -------------------------#
use tests 4; # HTMLHtmlElement

{
	is ref(
		my $elem = $doc->createElement('html'),
	), 'HTML::DOM::Element::HTML',
		"class for html";
	;
	$elem->attr(version => 'noisrev');

	test_attr $elem, qw/ version noisrev ekdosis /;
}

# -------------------------#
use tests 4; # HTMLHeadElement

{
	is ref(
		my $elem = $doc->createElement('head'),
	), 'HTML::DOM::Element::Head',
		"class for head";
	;
	$elem->attr(profile => 'eliforp');

	test_attr $elem, qw/ profile eliforp prolific /;
}

# -------------------------#
use tests 28; # HTMLLinkElement

{
	is ref(
		my $elem = $doc->createElement('link'),
	), 'HTML::DOM::Element::Link',
		"class for link";
	;
	$elem->attr(charset  => 'utf-8');
	$elem->attr(href     => '/styles.css');
	$elem->attr(hreflang => 'ru');
	$elem->attr(media    => 'radio');
	$elem->attr(rel      => 'ler');
	$elem->attr(rev      => 'ver');
	$elem->attr(target   => 'tegrat');
	$elem->attr(type     => 'application/pdf');

	ok!$elem->disabled                      ,     'get disabled';
	ok!$elem->disabled       (1),           , 'set/get disabled';
	ok $elem->disabled                      ,     'get disabled again';
	test_attr $elem, qw/ charset  utf-8           utf-32be        /;
	test_attr $elem, qw\ href     /styles.css     /stylesheet.css \;
	test_attr $elem, qw/ hreflang ru              fr              /;
	test_attr $elem, qw\ media    radio           avian-carrier   \;
	test_attr $elem, qw/ rel      ler             lure            /;
	test_attr $elem, qw\ rev      ver             ekd             \;
	test_attr $elem, qw/ target   tegrat          guitar          /;
	test_attr $elem, qw\ type     application/pdf text/richtext   \;
}

# -------------------------#
use tests 4; # HTMLTitleElement

{
	is ref(
		my $elem = $doc->createElement('title'),
	), 'HTML::DOM::Element::Title',
		"class for title";
	;

	test_attr $elem, 'text', '', 'tittle';
}

# -------------------------#
use tests 13; # HTMLMetaElement

{
	is ref(
		my $elem = $doc->createElement('meta'),
	), 'HTML::DOM::Element::Meta',
		"class for meta";
	;
	$elem->attr( content     => 'text/html; charset=utf-8');
	$elem->attr('http-equiv' => 'Content-Type');
	$elem->attr( name        => 'Fred');
	$elem->attr( scheme      => 'devious');

	test_attr $elem, 'content', 'text/html; charset=utf-8', 'no-cache';
	is $elem->httpEquiv,'Content-Type',          ,     'get httpEquiv';
	is $elem->httpEquiv('Pragma'), 'Content-Type', 'set/get httpEquiv';
	is $elem->httpEquiv,'Pragma',                'get httpEquiv again';
	test_attr $elem, qw` name    Fred             George             `;
	test_attr $elem, qw` scheme  devious          divisive           `;
}

# -------------------------#
use tests 7; # HTMLBaseElement

{
	is ref(
		my $elem = $doc->createElement('base'),
	), 'HTML::DOM::Element::Base',
		"class for base";
	;
	$elem->attr(href     => '/styles.css');
	$elem->attr(target   => 'tegrat');

	test_attr $elem, qw~ href   /styles.css /stylesheet.css  ~;
	test_attr $elem, qw~ target tegrat      guitar           ~;
}

# -------------------------#
use tests 6; # HTMLIsIndexElement

{
	is ref(
		my $elem = $doc->createElement('isindex'),
	), 'HTML::DOM::Element::IsIndex',
		"class for isindex";
	;
	$elem->attr(prompt     => 'Yayayyayayaayay');

	is $elem->form, undef, 'IsIndex undef form';
	(my $form = $doc->createElement('form'))->appendChild(
		$doc->createElement('div'));
	$form->firstChild->appendChild($elem);
	is $elem->form, $form, 'IsIndex form';

	test_attr $elem, qw @ prompt Yayayyayayaayay     01504           @;
}

# -------------------------#
use tests 10; # HTMLStyleElement

{
	is ref(
		my $elem = $doc->createElement('style'),
	), 'HTML::DOM::Element::Style',
		"class for style";
	;
	$elem->attr(media    => 'radio');
	$elem->attr(type     => 'application/pdf');

	ok!$elem->disabled                           ,      'get disabled';
	ok!$elem->disabled       (1),                ,  'set/get disabled';
	ok $elem->disabled                           ,'get disabled again';
	test_attr $elem, qw! media radio           avian-carrier         !;
	test_attr $elem, qw! type  application/pdf text/richtext         !;
}

# -------------------------#
use tests 21; # HTMLBodyElement

{
	is ref(
		my $elem = $doc->createElement('body'),
	), 'HTML::DOM::Element::Body',
		"class for body";
	;
	$elem->attr(aLink     => 'red');
	$elem->attr(background=> 'orange');
	$elem->attr(bgColor   => 'yellow');
	$elem->attr(link      => 'green');
	$elem->attr(text      => 'blue');
	$elem->attr(vLink     => 'dingo');

	test_attr $elem, qw 2 aLink      red     kokkino           2;
	test_attr $elem, qw 3 background orange  portokali         3;
	test_attr $elem, qw 4 bgColor    yellow  kitrino           4;
	test_attr $elem, qw 5 link       green   prasino           5;
	test_attr $elem, qw 6 text       blue    mple              6;
	test_attr $elem, qw 7 vLink      dingo   eidos_skylou      7;

	my $doc = new HTML::DOM; $doc->open;
	@Window::ISA = qw (HTML::DOM::EventTarget);
	my $wind = bless [], "Window";
	$elem = $doc->body;
	$doc->event_parent( $wind );
	
	my $scratch;
	my $sub = sub{
	 $scratch .= refaddr($_[0]->target) . ' '
	           . refaddr($_[0]->currentTarget) . ' '
	 };
	$elem->onion($sub);
	is $wind->onion, $sub,
	 'assignment to body->onion assigns to window->onion';
	$elem->addEventListener('ion', sub { $scratch .= "body " });
	$elem->trigger_event('ion');
	is $scratch, "body " .refaddr($elem) . " " . refaddr($wind) . " ",
	   "handler assigned to body->on* vs body->addEventListener";
}

# -------------------------#
use tests 9; # HTMLUListElement

{
	is ref(
		my $elem = $doc->createElement('ul'),
	), 'HTML::DOM::Element::UL',
		"class for ul";
	;
	$elem->attr(type     => 'dIsc');

	ok!$elem->compact                           ,      'get compact';
	ok!$elem->compact       (1),                ,  'set/get compact';
	ok $elem->compact                           ,'get compact again';
	$elem->compact(1);
	is $elem->getAttribute('compact'), 'compact',
	 'ul’s compact is set to "compact" when true';
	$elem->compact($false);
	is $elem->attr('compact'), undef,
	 'ul’s compact is deleted when set to false';

	test_attr $elem, qw 2 type      disc square           2;
}

# -------------------------#
use tests 12; # HTMLOListElement

{
	is ref(
		my $elem = $doc->createElement('ol'),
	), 'HTML::DOM::Element::OL',
		"class for ol";
	;
	$elem->attr(compact => '1');
	$elem->attr(type     => 'i');
	$elem->attr(start     => '4');

	ok $elem->compact                           ,      'get compact';
	ok $elem->compact       (0),                ,  'set/get compact';
	ok!$elem->compact                           ,'get compact again';
	$elem->compact(1);
	is $elem->getAttribute('compact'), 'compact',
	 'ol’s compact is set to "compact" when true';
	$elem->compact($false);
	is $elem->attr('compact'), undef,
	 'ol’s compact is deleted when set to false';

	test_attr $elem, qw 2 type      i a           2;
	test_attr $elem, qw 2 start     4 5           2;
}

# -------------------------#
use tests 6; # HTMLDListElement

{
	is ref(
		my $elem = $doc->createElement('dl'),
	), 'HTML::DOM::Element::DL',
		"class for dl";
	;
	$elem->attr(compact => '1');

	ok $elem->compact                           ,      'get compact';
	ok $elem->compact       (0),                ,  'set/get compact';
	ok!$elem->compact                           ,'get compact again';
	$elem->compact(1);
	is $elem->getAttribute('compact'), 'compact',
	 'dl’s compact is set to "compact" when true';
	$elem->compact($false);
	is $elem->attr('compact'), undef,
	 'dl’s compact is deleted when set to false';
}

# -------------------------#
use tests 6; # HTMLDirectoryElement

{
	is ref(
		my $elem = $doc->createElement('dir'),
	), 'HTML::DOM::Element::Dir',
		"class for dir";
	;
	$elem->attr(compact => '1');

	ok $elem->compact                           ,      'get compact';
	ok $elem->compact       (0),                ,  'set/get compact';
	ok!$elem->compact                           ,'get compact again';
	$elem->compact(1);
	is $elem->getAttribute('compact'), 'compact',
	 'dir’s compact is set to "compact" when true';
	$elem->compact($false);
	is $elem->attr('compact'), undef,
	 'dir’s compact is deleted when set to false';
}

# -------------------------#
use tests 6; # HTMLMenuElement

{
	is ref(
		my $elem = $doc->createElement('menu'),
	), 'HTML::DOM::Element::Menu',
		"class for menu";
	;
	$elem->attr(compact => '1');

	ok $elem->compact                           ,      'get compact';
	ok $elem->compact       (0),                ,  'set/get compact';
	ok!$elem->compact                           ,'get compact again';	$elem->compact(1);
	is $elem->getAttribute('compact'), 'compact',
	 'menu’s compact is set to "compact" when true';
	$elem->compact($false);
	is $elem->attr('compact'), undef,
	 'menu’s compact is deleted when set to false';
}

# -------------------------#
use tests 7; # HTMLLIElement

{
	is ref(
		my $elem = $doc->createElement('li'),
	), 'HTML::DOM::Element::LI',
		"class for li";
	;
	$elem->attr(type     => 'disc');
	$elem->attr(value     => '30');

	test_attr $elem, qw 2 type      disc square       2;
	test_attr $elem, qw 2 value     30   40           2;
}

# -------------------------#
use tests 4; # HTMLDivElement

{
	is ref(
		my $elem = $doc->createElement('div'),
	), 'HTML::DOM::Element::Div',
		"class for div";
	;
	$elem->attr(align     => 'leFT');

	test_attr $elem, qw 2 align left right       2;
}

# -------------------------#
use tests 9; # HTMLHeadingElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement("h$_"),
	), 'HTML::DOM::Element::Heading',
		"class for h$_"
	for 1..6;

	$elem->attr(align     => 'LEFt');

	test_attr $elem, qw 2 align left right       2;
}

# -------------------------#
use tests 5; # HTMLQuoteElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement($_),
	), 'HTML::DOM::Element::Quote',
		"class for $_"
	for qw wq blockquotew;

	$elem->attr(cite     => 'me.html');

	test_attr $elem, qw 2 cite me.html you.html       2;
}

# -------------------------#
use tests 4; # HTMLPreElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('pre'),
	), 'HTML::DOM::Element::Pre',
		"class for pre";

	$elem->attr(width     => '7');

	test_attr $elem, qw 2 width 7 8       2;
}

# -------------------------#
use tests 4; # HTMLBRElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('br'),
	), 'HTML::DOM::Element::Br',
		"class for br";

	$elem->attr(clear     => 'leFt');

	test_attr $elem, qw 2 clear left all       2;
}

# -------------------------#
use tests 10; # HTMLBaseFontElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('basefont'),
	), 'HTML::DOM::Element::BaseFont',
		"class for basefont";

	$elem->attr(color     => 'red');
	$elem->attr(face     => 'visage');
	$elem->attr(size    => '3');

	no # stupid
	warnings # about
	'qw'; # !!!
	test_attr $elem, qw 2 color red    #000000     2;
	test_attr $elem, qw 2 face  visage mien      2;
	test_attr $elem, qw 2 size  3      4       2;
}

# -------------------------#
use tests 10; # HTMLFontElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('font'),
	), 'HTML::DOM::Element::Font',
		"class for font";

	$elem->attr(color     => 'red');
	$elem->attr(face     => 'visage');
	$elem->attr(size    => '3');

	no warnings qw e qw e ;
	test_attr $elem, qw 2 color red    #000000     2;
	test_attr $elem, qw 2 face  visage mien      2;
	test_attr $elem, qw 2 size  3      4       2;
}

# -------------------------#
use tests 15; # HTMLHRElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('hr'),
	), 'HTML::DOM::Element::HR',
		"class for hr";

	$elem->attr(align     => 'lEFt');
	$elem->attr(noshade     => '1');
	$elem->attr(size    => '3');
	$elem->attr(width    => '3');

	test_attr $elem, qw 2 align left center     2;
	ok $elem->noShade                  ,      'get HR’s noShade';
	ok $elem->noShade(0),              ,  'set/get HR’s noShade';
	ok!$elem->noShade                  ,      'get HR’s noShade again';
	$elem->noShade(1);
	is $elem->getAttribute('noshade'), 'noshade',
	 'hr’s noshade is set to "noshade" when true';
	$elem->noShade($false);
	is $elem->attr('noshade'), undef,
	 'hr’s noshade is deleted when set to false';

	test_attr $elem, qw 2 size  3      4       2;
	test_attr $elem, qw 2 width 3      4       2;
}

# -------------------------#
use tests 8; # HTMLModElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement($_),
	), 'HTML::DOM::Element::Mod',
		"class for $_"
	for qw wins delw;

	$elem->attr(cite     => 'me.html');
	$elem->attr(datetime => 'today');

	test_attr $elem, qw 2 cite     me.html you.html     2;
	test_attr $elem, qw 2 dateTime today   yesterday    2;
}

# -------------------------#
use tests 43+57; # HTMLAnchorElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('a'),
	), 'HTML::DOM::Element::A',
		"class for a";

	$elem->attr(accesskey => 'F');
	$elem->attr(charset   => 'iso-8859-3');
	$elem->attr(coords    => '1,2,3,34');
	$elem->attr(href      => 'here');
	$elem->attr(hreflang  => 'en');
	$elem->attr(name      => 'Fred');
	$elem->attr(rel       => 'foo');
	$elem->attr(rev       => 'phu');
	$elem->attr(shape     => 'circle');
	$elem->attr(tabIndex  => '78');
	$elem->attr(target    => 'bull\'s-eye');
	$elem->attr(type      => 'application/pdf');

	no warnings qw: qw: ;
	test_attr $elem, qw 2 accessKey F               G           2;
	test_attr $elem, qw 2 charset   iso-8859-3      x-mac-roman 2;
	test_attr $elem, qw 5 coords    1,2,3,34        9,8,7,6     5;
	test_attr $elem, qw 2 href      here            there       2;
	test_attr $elem, qw 2 hreflang  en              el          2;
	test_attr $elem, qw 2 name      Fred            George      2;
	test_attr $elem, qw 2 rel       foo             bar         2;
	test_attr $elem, qw 2 rev       phu             bah         2;
	test_attr $elem, qw 2 shape     circle          ellipsoid   2;
	test_attr $elem, qw 2 tabIndex  78              81          2;
	test_attr $elem, qw 2 target    bull's-eye      whatever    2;
	test_attr $elem, qw 2 type      application/pdf text/html   2;

	test_event $elem => $_ for qw/blur focus/;


	# Location methods not included in DOM 1 or 2 (but implemented in
	# every browser since NS2 and included in HTML 5)

	$doc->open(); 
	# Doc currently has no base URL and href is relative.
	for(qw( hash host hostname pathname port protocol search )) {
		is $elem->$_, '',
		 "$_ is empty str when href is relative to nothing";
		$elem->$_("dwext");
		is $elem->$_, "",
		 "setting $_ sets it to '' when href is relative to nowt";
	}

	$elem->attr(href => undef );
	for(qw( hash host hostname pathname port protocol search )) {
		is $elem->$_, '',
		 "$_ is empty str when href does not exist";
		$elem->$_("dwext");
		is $elem->$_, "",
		 "setting $_ sets it to '' in absence of href";
	}

	$elem->attr(href => "http://clit.brile:232/bror?clat#brin");
	is $elem->hash, "#brin",
	 'hash when href is set but doc->base is blank';
	is $elem->host, "clit.brile:232",
	 'host when href is set but doc->base is blank';
	is $elem->hostname, "clit.brile",
	 'hostname when href is set but doc->base is blank';
	is $elem->pathname, "/bror",
	 'pathname when href is set but doc->base is blank';
	is $elem->port, "232",
	 'port when href is set but doc->base is blank';
	is $elem->protocol, "http:",
	 'protocol when href is set but doc->base is blank';
	is $elem->search, "?clat",
	 'search when href is set but doc->base is blank';

	$doc->write("<base href='http://fext.gred/clow/'>");
	$doc->close();
	$elem->attr(href => "blelp");
	is $elem->hash, "", 'hash is blank when missing from URL';
	is $elem->hash("#brun"), '', 'hash retval when setting';
	is $elem->href, "http://fext.gred/clow/blelp#brun",
	 'setting hash modifies href and makes in absolute';
	$elem->attr(href => "blelp");
	is $elem->hostname, "fext.gred",
	 'retval of hostname when href is relative';
	$elem->attr(href => "http://fext.gred:123/blelp");
	is $elem->hostname("blen.baise"), 'fext.gred',
	 'retval of hostname when setting and when there is a port';
	is $elem->href, "http://blen.baise:123/blelp",
	 "setting hostname modifies href";
	$elem->attr(href => "http://blan:2323/");
	is $elem->host, "blan:2323", 'host';
	is $elem->host("blan"), 'blan:2323',
	 'retval of host when setting';
	is $elem->href, "http://blan/", 'setting host';
	is $elem->pathname, "/", 'pathname';
	is $elem->pathname("/bal/"), '/', 'pathname retval when setting';
	is $elem->href, "http://blan/bal/", 'setting pathname';
	$elem->href("http://blid:3838/");
	is $elem->port, "3838", "port";
	is $elem->port("3865"), 3838, 'port retval when setting';
	is $elem->href, "http://blid:3865/", 'setting port';
	is $elem->protocol , "http:", 'protocol';
	is $elem->protocol("ftp"), "http:", 'retval when setting protocol';
	is $elem->href, 'ftp://blid:3865/', 'effect of setting protocol';
	is $elem->search, '', 'search is blank when URL contains no ?';
	is $elem->search("?oeet"), '', 'retval of search when setting';
	is $elem->href,'ftp://blid:3865/?oeet', 'result of setting search';
	$elem->search('?');
	is $elem->href,'ftp://blid:3865/?','result of setting search to ?';
}

# -------------------------#
use tests 39; # HTMLImageElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('img'),
	), 'HTML::DOM::Element::Img',
		"class for img";

	$elem->attr(name     => 'Fred');
	$elem->attr(align    => 'lefT');
	$elem->attr(alt      => 'blank');
	$elem->attr(border   => '7');
	$elem->attr(height   => '8');
	$elem->attr(hspace   => '9');
	$elem->attr(isMap    => '1');
	$elem->attr(longdesc => 'phu');
	$elem->attr(src      => 'circle');
	$elem->attr(usemap   => '1');
	$elem->attr(vspace   => '10');
	$elem->attr(width    => '11');

	no warnings qw: qw: ;
	test_attr $elem, qw 2 name     Fred    George    2;
	test_attr $elem, qw 2 align    left    right     2;
	test_attr $elem, qw 5 alt      blank   whinte    5;
	test_attr $elem, qw 2 border   7       8         2;
	test_attr $elem, qw 2 height   8       10        2;
	test_attr $elem, qw 2 hspace   9       56        2;

	ok $elem->isMap                  ,      'get Img’s isMap';
	ok $elem->isMap(0),              ,  'set/get Img’s isMap';
	ok!$elem->isMap                  ,      'get Img’s isMap again';
	$elem->isMap(1);
	is $elem->getAttribute('ismap'), 'ismap',
	 'img’s ismap is set to "ismap" when true';
	$elem->isMap($false);
	is $elem->attr('ismap'), undef,
	 'img’s ismap is deleted when set to false';

	test_attr $elem, qw 2 longDesc phu     bah       2;
	test_attr $elem, qw 2 src      circle  ellipsoid 2;
	test_attr $elem, qw 2 useMap   1       two       2;
	test_attr $elem, qw 3 vspace   10      12        3;
	test_attr $elem, qw 2 width    11      79        2;
}

# -------------------------#
use tests 57; # HTMLObjectElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('object'),
	), 'HTML::DOM::Element::Object',
		"class for object";

	is $elem->form, undef, 'Object’s undef form';
	(my $form = $doc->createElement('form'))->appendChild(
		$doc->createElement('div'));
	$form->firstChild->appendChild($elem);
	is $elem->form, $form, 'Object’s form';

	$elem->attr(code     => 'e-doc');
	$elem->attr(align    => 'Left');
	$elem->attr(archive  => 'left');
	$elem->attr(border   => '7');
	$elem->attr(codebase => '7');
	$elem->attr(codeType => 'text/tcl');
	$elem->attr(data     => 'text/tcl');
	$elem->attr(declare  => 'text/tcl');
	$elem->attr(height   => '8');
	$elem->attr(hspace   => '9');
	$elem->attr(name     => 'Fred');
	$elem->attr(standby  => 'Fred');
	$elem->attr(tabIndex => '90');
	$elem->attr(type     => 'image/gif');
	$elem->attr(usemap   => '1');
	$elem->attr(vspace   => '10');
	$elem->attr(width    => '11');

	no warnings qw: qw: ;
	test_attr $elem, qw 2 code     e-doc    f-doc         2;
	test_attr $elem, qw 2 align    left     right         2;
	test_attr $elem, qw 2 archive  left     leaving       2;
	test_attr $elem, qw 2 border   7        8             2;
	test_attr $elem, qw 2 codeBase 7        seen          2;
	test_attr $elem, qw 2 codeType text/tcl thnig/wierd   2;
	test_attr $elem, qw 2 data     text/tcl =1/(tcl/text) 2;

	ok $elem->declare              ,      'get Object’s declare';
	ok $elem->declare(0),          ,  'set/get Object’s declare';
	ok!$elem->declare              ,      'get Object’s declare again';
	$elem->declare(1);
	is $elem->getAttribute('declare'), 'declare',
	 'object’s declare is set to "declare" when true';
	$elem->declare($false);
	is $elem->attr('declare'), undef,
	 'object’s declare is deleted when set to false';

	test_attr $elem, qw 2 height   8         10      2;
	test_attr $elem, qw 2 hspace   9         56      2;
	test_attr $elem, qw 2 name     Fred      George  2;
	test_attr $elem, qw 2 standby  Fred      Will    2;
	test_attr $elem, qw 4 tabIndex 90        123     4;
	test_attr $elem, qw 2 type     image/gif foo/bar 2;
	test_attr $elem, qw 2 useMap   1         two     2;
	test_attr $elem, qw 3 vspace   10        12      3;
	test_attr $elem, qw 2 width    11        79      2;

	is +()=$elem->contentDocument, 0, 'object contentDocument';
}

# -------------------------#
use tests 13; # HTMLParamElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('param'),
	), 'HTML::DOM::Element::Param',
		"class for param";

	$elem->attr(name      => 'Fred');
	$elem->attr(type      => 'image/gif');
	$elem->attr(value     => '1');
	$elem->attr(valueType => 'dAtA');

	no warnings qw: qw: ;
	test_attr $elem, qw 2 name      Fred      George  2;
	test_attr $elem, qw 2 type      image/gif foo/bar 2;
	test_attr $elem, qw 2 value     1         two     2;
	test_attr $elem, qw 3 valueType data      ref     3;
}

# -------------------------#
use tests 33; # HTMLAppletElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('applet'),
	), 'HTML::DOM::Element::Applet',
		"class for applet";

	$elem->attr(align    => 'lEft');
	$elem->attr(alt      => 'left');
	$elem->attr(archive  => 'left');
	$elem->attr(code     => 'e-doc');
	$elem->attr(codebase => '7');
	$elem->attr(height   => '8');
	$elem->attr(hspace   => '9');
	$elem->attr(name     => 'Fred');
	$elem->attr(object   => 'Fred');
	$elem->attr(vspace   => '10');
	$elem->attr(width    => '11');

	test_attr $elem, qw 2 align    left     right   2;
	test_attr $elem, qw 2 alt      left     alto    2;
	test_attr $elem, qw 2 archive  left     leaving 2;
	test_attr $elem, qw 2 code     e-doc    f-doc   2;
	test_attr $elem, qw 2 codeBase 7        seen    2;
	test_attr $elem, qw 2 height   8        10      2;
	test_attr $elem, qw 2 hspace   9        56      2;
	test_attr $elem, qw 2 name     Fred     George  2;
	test_attr $elem, qw 2 object   Fred     George  2;
	test_attr $elem, qw 3 vspace   10       12      3;
	test_attr $elem, qw 2 width    11       79      2;
}

# -------------------------#
use tests 6; # HTMLMapElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('map'),
	), 'HTML::DOM::Element::Map',
		"class for map";

	$elem->attr(name     => 'Fred');
	test_attr $elem, qw 2 name     Fred     George  2;

	my $areas = $elem->areas;

	my $area1 = $doc->createElement('area');
	my $area2 = $doc->createElement('area');
	my $area3 = $doc->createElement('area');

	$elem->appendChild($_) for $area1, $area2, $area3;

	is $areas->length, 3, 'number of areas in map';
	use Scalar::Util 1.14 'refaddr';
	is_deeply [map refaddr $_, @$areas],
	          [map refaddr $_, $area1, $area2, $area3], 'Map’s areas';
}

# -------------------------#
use tests 27+57; # HTMLAreaElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('area'),
	), 'HTML::DOM::Element::Area',
		"class for area";

	$elem->attr(accesskey => 'L');
	$elem->attr(alt       => 'left');
	$elem->attr(coords    => '1,2,2,4,5,6');
	$elem->attr(href      => 'e-doc');
	$elem->attr(nohref    => '1');
	$elem->attr(shape     => 'rect');
	$elem->attr(tabindex  => '9');
	$elem->attr(target    => 'Fred');

	no # silly
	warnings # about
	'qw';
	test_attr $elem, qw 2 accessKey L           M           2;
	test_attr $elem, qw 2 alt       left        alto        2;
	test_attr $elem, qw 3 coords    1,2,2,4,5,6 9,8,7,6,5,4 3;
	test_attr $elem, qw 2 href      e-doc       f-doc       2;

	ok $elem->noHref              ,      'get Area’s noHref';
	ok $elem->noHref(0),          ,  'set/get Area’s noHref';
	ok!$elem->noHref              ,      'get Area’s noHref again';
	$elem->noHref(1);
	is $elem->getAttribute('nohref'), 'nohref',
	 'area’s nohref is set to "nohref" when true';
	$elem->noHref($false);
	is $elem->attr('nohref'), undef,
	 'area’s nohref is deleted when set to false';

	test_attr $elem, qw 2 shape    rect     poly    2;
	test_attr $elem, qw 2 tabIndex 9        56      2;
	test_attr $elem, qw 2 target   Fred     George  2;


	# Location methods not included in DOM 1 or 2 (but implemented in
	# every browser since NS2 and included in HTML 5)

	$doc->open(); 
	# Doc currently has no base URL and href is relative.
	for(qw( hash host hostname pathname port protocol search )) {
		is $elem->$_, '',
		 "$_ is empty str when href is relative to nothing";
		$elem->$_("dwext");
		is $elem->$_, "",
		 "setting $_ sets it to '' when href is relative to nowt";
	}

	$elem->attr(href => undef );
	for(qw( hash host hostname pathname port protocol search )) {
		is $elem->$_, '',
		 "$_ is empty str when href does not exist";
		$elem->$_("dwext");
		is $elem->$_, "",
		 "setting $_ sets it to '' in absence of href";
	}

	$elem->attr(href => "http://clit.brile:232/bror?clat#brin");
	is $elem->hash, "#brin",
	 'hash when href is set but doc->base is blank';
	is $elem->host, "clit.brile:232",
	 'host when href is set but doc->base is blank';
	is $elem->hostname, "clit.brile",
	 'hostname when href is set but doc->base is blank';
	is $elem->pathname, "/bror",
	 'pathname when href is set but doc->base is blank';
	is $elem->port, "232",
	 'port when href is set but doc->base is blank';
	is $elem->protocol, "http:",
	 'protocol when href is set but doc->base is blank';
	is $elem->search, "?clat",
	 'search when href is set but doc->base is blank';

	$doc->write("<base href='http://fext.gred/clow/'>");
	$doc->close();
	$elem->attr(href => "blelp");
	is $elem->hash, "", 'hash is blank when missing from URL';
	is $elem->hash("#brun"), '', 'hash retval when setting';
	is $elem->href, "http://fext.gred/clow/blelp#brun",
	 'setting hash modifies href and makes in absolute';
	$elem->attr(href => "blelp");
	is $elem->hostname, "fext.gred",
	 'retval of hostname when href is relative';
	$elem->attr(href => "http://fext.gred:123/blelp");
	is $elem->hostname("blen.baise"), 'fext.gred',
	 'retval of hostname when setting and when there is a port';
	is $elem->href, "http://blen.baise:123/blelp",
	 "setting hostname modifies href";
	$elem->attr(href => "http://blan:2323/");
	is $elem->host, "blan:2323", 'host';
	is $elem->host("blan"), 'blan:2323',
	 'retval of host when setting';
	is $elem->href, "http://blan/", 'setting host';
	is $elem->pathname, "/", 'pathname';
	is $elem->pathname("/bal/"), '/', 'pathname retval when setting';
	is $elem->href, "http://blan/bal/", 'setting pathname';
	$elem->href("http://blid:3838/");
	is $elem->port, "3838", "port";
	is $elem->port("3865"), 3838, 'port retval when setting';
	is $elem->href, "http://blid:3865/", 'setting port';
	is $elem->protocol , "http:", 'protocol';
	is $elem->protocol("ftp"), "http:", 'retval when setting protocol';
	is $elem->href, 'ftp://blid:3865/', 'effect of setting protocol';
	is $elem->search, '', 'search is blank when URL contains no ?';
	is $elem->search("?oeet"), '', 'retval of search when setting';
	is $elem->href,'ftp://blid:3865/?oeet', 'result of setting search';
	$elem->search('?');
	is $elem->href,'ftp://blid:3865/?','result of setting search to ?';
}

# -------------------------#
use tests 27; # HTMLScriptElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('script'),
	), 'HTML::DOM::Element::Script',
		"class for script";

	is $elem->text, '', 'script->text when empty';
	$elem->appendChild($doc->createTextNode(''));
	is $elem->text, '', 'script->text when blank';
	$elem->firstChild->data('foo');
	test_attr $elem, qw/text foo bar/;
	is $elem->firstChild->data, 'bar',
		'setting script->text modifies its child node';

	$elem->attr(for     => 'L');
	$elem->attr(event   => 'left');
	$elem->attr(charset => 'utf-8');
	$elem->attr(defer   => '1');
	$elem->attr(src     => '1');
	$elem->attr(type    => 'application/x-ecmascript');

	no # silly
	warnings # about
	'qw';
	test_attr $elem, qw 2 htmlFor L     M          2;
	test_attr $elem, qw 2 event   left  alto       2;
	test_attr $elem, qw 3 charset utf-8 iso-8859-7 3;

	ok $elem->defer              ,      'get Script’s defer';
	ok $elem->defer(0),          ,  'set/get Script’s defer';
	ok!$elem->defer              ,      'get Script’s defer again';
	$elem->defer(1);
	is $elem->getAttribute('defer'), 'defer',
	 'script’s defer is set to "defer" when true';
	$elem->defer($false);
	is $elem->attr('defer'), undef,
	 'script’s defer is deleted when set to false';

	test_attr $elem, qw-src  1                        3              -;
	test_attr $elem, qw.type application/x-ecmascript text/javascript.;
}

# -------------------------#
use tests 7; # HTMLFrameSetElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('frameset'),
	), 'HTML::DOM::Element::FrameSet',
		"class for frameset";

	$elem->attr(rows     => '*,50%');
	$elem->attr(cols   => '50%,10%,*');

	no # silly
	warnings # about
	'qw';
	test_attr $elem, qw 2 rows *,50% *,70%         2;
	test_attr $elem, qw 2 cols 50%,10%,* 10%,*,10% 2;
}

# -------------------------#
use tests 36; # HTMLFrameElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('frame'),
	), 'HTML::DOM::Element::Frame',
		"class for frame";

	$elem->attr(frameborder  => '1');
	$elem->attr(longdesc     => 'shortescritoire');
	$elem->attr(marginheight => '50');
	$elem->attr(marginwidth  => '5010');
	$elem->attr(name         => '50,10,*'); # nice name
	$elem->attr(noresize     => '50,10,*');
	$elem->attr(scrolling    => 'yEs');
	$elem->attr(src          => '50,10,*');

	no # silly
	warnings # about
	'qw';
	test_attr $elem, qw 2 frameBorder 1 0        2;
	test_attr $elem, qw 2 longDesc shortescritoire shortEscritoire 2;
	test_attr $elem, qw 2 marginHeight 50      500  2;
	test_attr $elem, qw 2 marginWidth  5010    1500 2;
	test_attr $elem, qw 2 name         50,10,* Bob  2;

	ok $elem->noResize             ,      'get Frame’s noResize';
	ok $elem->noResize(0),         ,  'set/get Frame’s noResize';
	ok!$elem->noResize             ,      'get Frame’s noResize again';
	$elem->noResize(1);
	is $elem->getAttribute('noresize'), 'noresize',
	 'frame’s noresize is set to "noresize" when true';
	$elem->noResize($false);
	is $elem->attr('noresize'), undef,
	 'frame’s noresize is deleted when set to false';

	test_attr $elem, qw 2 scrolling yes     auto    2;
	test_attr $elem, qw 2 src       50,10,* foo.gif 2;

	# weird frameborder test; strictly, since this is a value list, it
	# has to be normalised to lc
	$elem->setAttribute('frameborder'=>'bOOhoO');
	is frameBorder $elem, 'boohoo', 'frame->frameBorder is lc';

	is +()=$elem->contentWindow, 0,'no frame->contentWindow';
	is +()=$elem->contentDocument, 0,
		'  or frame->contentDocument by default';
	require HTML::DOM::View;
	is +()=$elem->contentWindow(my $view = bless[],'HTML::DOM::View'),
		0, 'contentWindow\'s retval when initially assigned';
	is $elem->contentWindow, $view,
		'the assignment to frame->contentWindow worked';
	$view->document("foo");
	is $elem->contentDocument, 'foo',
	  'frame contentDocument retrieved from contentWindow->document';
	is $elem->contentWindow(bless[],'HTML::DOM::View'), $view,
		'retval when setting frame’s contentWindow again';
	is +()=$elem->contentDocument, 0,
	    'no frame->contentDocument when the window present has no doc';
}

# -------------------------#
use tests 39; # HTMLIFrameElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('iframe'),
	), 'HTML::DOM::Element::IFrame',
		"class for iframe";

	$elem->attr(align        => 'leFt');
	$elem->attr(frameborder  => '1');
	$elem->attr(height       => '2');
	$elem->attr(longdesc     => 'shortescritoire');
	$elem->attr(marginheight => '50');
	$elem->attr(marginwidth  => '5010');
	$elem->attr(name         => '50,10,*'); # nice name
	$elem->attr(scrolling    => 'yeS');
	$elem->attr(src          => '50,10,*');
	$elem->attr(width        => '50');

	no # silly
	warnings # about
	'qw';
	test_attr $elem, qw 2 align       left right 2;
	test_attr $elem, qw 2 frameBorder 1    0     2;
	test_attr $elem, qw 4 height      2    23    4;
	test_attr $elem, qw 2 longDesc shortescritoire shortEscritoire 2;
	test_attr $elem, qw 2 marginHeight 50      500  2;
	test_attr $elem, qw 2 marginWidth  5010    1500 2;
	test_attr $elem, qw 2 name         50,10,* Bob  2;
	test_attr $elem, qw 2 scrolling yes     auto    2;
	test_attr $elem, qw 2 src       50,10,* foo.gif 2;
	test_attr $elem, qw 2 width     50      500     2;

	# weird frameborder test; strictly, since this is a value list, it
	# has to be normalised to lc
	$elem->setAttribute('frameborder'=>'bOOhoO');
	is frameBorder $elem, 'boohoo', 'frame->frameBorder is lc';

	is +()=$elem->contentWindow, 0,'no iframe->contentWindow';
	is +()=$elem->contentDocument, 0,
		'  or iframe->contentDocument by default';
	require HTML::DOM::View;
	is +()=$elem->contentWindow(my $view = bless[],'HTML::DOM::View'),
		0, 'contentWindow\'s retval when initially assigned';
	is $elem->contentWindow, $view,
		'the assignment to iframe->contentWindow worked';
	$view->document("foo");
	is $elem->contentDocument, 'foo',
	  'iframe contentDocument retrieved from contentWindow->document';
	is $elem->contentWindow(bless[],'HTML::DOM::View'), $view,
		'retval when setting iframe’s contentWindow again';
	is +()=$elem->contentDocument, 0,
	   'no iframe->contentDocument when the window present has no doc';
}

# -------------------------#
use tests 4; # HTMLParagraphElement

{
	is ref(
		my $elem = $doc->createElement('p'),
	), 'HTML::DOM::Element::P',
		"class for p";
	;
	$elem->attr(align     => 'leFT');

	test_attr $elem, qw 2 align left right       2;
}

# -------------------------#
use tests 2; # content_offset
{
 my $doc = new HTML::DOM;
 $doc->elem_handler(script => sub {
  my $doc = shift;
  eval shift->firstChild->data;
 });
 $doc->write(
   '<a href="clon">skext</a>'
  .'<script>$doc->write("<br>")</script>'
  .'<a href="squed">glit</a>'
 );
 for(scalar $doc->links) {
  is $$_[0]->content_offset, 15, 'content_offset';
  is $$_[1]->content_offset, 76, 'content_offset after document.write';
 }
}
