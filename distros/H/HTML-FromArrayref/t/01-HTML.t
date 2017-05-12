#!perl -T

use Test::More;

BEGIN { use_ok('HTML::FromArrayref', 'HTML', ':TAGS', ':DOCTYPES'); }

is(
	html_strict(), << '', 'prints an HTML 4.01 Strict doctype'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
	"http://www.w3.org/TR/html4/strict.dtd">

);

is(
	HTML( [ p => 'foo' ] ),
	'<p>foo</p>',
	'prints an HTML element'
);

is(
	HTML( [ p => { attrib => 'this&that' }, 'foo' ] ),
	'<p attrib="this&amp;that">foo</p>',
	'encodes attribute values'
);

is(
	HTML( [ p => { attrib => undef }, 'foo' ] ),
	'<p>foo</p>',
	'skips attribute with undefined values'
);

is(
	HTML( [ img => { src => 'image.png' }, 'foo' ], ['br'] ),
	'<img src="image.png"><br>',
	'prints void HTML elements without closing tags'
);

is(
	HTML( [ p => undef ] ),
	'<p></p>',
	'prints non-void empty elements with closing tags'
);

is(
	HTML( [ p => [ b => 'bold' ], 'foo' ] ),
	'<p><b>bold</b>foo</p>',
	'prints nested HTML elements'
);

is(
	HTML( [ p => [ 0 && b => 'notbold' ], 'foo' ] ),
	'<p>notboldfoo</p>',
	'skips HTML elements with false tag names'
);

is(
	HTML( [ p => 'foo', [[ '<i>italics</i>' ]] ] ),
	'<p>foo<i>italics</i></p>',
	'leaves already-escaped text alone'
);

is(
	start_tag( p => { class => 'test-class' } ),
	'<p class="test-class">',
	'prints a start tag'
);

done_testing();