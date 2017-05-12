#!perl -T

use Test::More tests => 4;

BEGIN { use_ok('HTML::FromArrayref', ':TAGS'); }

is(
	start_tag( 'div' ),
	'<div>',
	'prints a start tag'
);

is(
	start_tag( div => { attrib => 'this&that' } ),
	'<div attrib="this&amp;that">',
	'encodes attribute values'
);

is(
	end_tag( 'textarea' ),
	'</textarea>',
	'prints an end tag'
);