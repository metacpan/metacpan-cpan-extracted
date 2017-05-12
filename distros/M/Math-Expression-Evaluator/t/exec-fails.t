use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 4 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new works");

sub exec_fail {
	my ($string, $hash, $explanation) = @_;
	$m->parse($string);
	eval { $m->val($hash) };
	ok($@, $explanation);
}

exec_fail 'a',		{},		'undefined variable 1';
exec_fail 'a',		{b => 1},	'undefined variable 2';
exec_fail 'foo()',	{},		'undefined function';
