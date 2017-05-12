#!perl
use strict;
use warnings;
use Test::More 'no_plan';

use_ok('Math::Symbolic');
use_ok('Math::SymbolicX::ParserExtensionFactory');

use Math::Symbolic qw/parse_from_string/;

use Math::SymbolicX::ParserExtensionFactory (
	myfunction => sub {
		ok(1, 'myfunction called at the right time');
		ok($_[0] eq 'myargument*(2-1)');
		return Math::Symbolic::Constant->new(5);
	},
);

ok(1, 'Still alive after modifying the parser.');

my $parsed = parse_from_string('1 + myfunction(myargument*(2-1)) * myfunction(myargument*(2-1))');

ok(ref $parsed eq 'Math::Symbolic::Operator', 'parsed alright');

ok($parsed->value()==26, 'works alright');




