use strict;
use warnings;
use blib;
use Test::More;

plan tests => 10;

use_ok('Mail::Karmasphere::Parser::Record');

*guess = \&Mail::Karmasphere::Parser::Record::guess_identity_type;

for (qw(
		123.45.6.7
		123.45.6.7/24
		123.45.6.7/8
		3.5.6.7/8
		3.5.6.7-4.5.6.7
		3.5.6
		3
		3-5
			)) {
	is('ip4', guess($_), "$_ is an IP4 range");
}

for (qw(
		123a
			)) {
	isnt('ip4', guess($_), "$_ is not an IP4 range");
}
