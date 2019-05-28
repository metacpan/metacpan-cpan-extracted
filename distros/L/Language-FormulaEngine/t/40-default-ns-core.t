#! /usr/bin/env perl
use Test2::V0;
use Language::FormulaEngine;

my @tests= (
	[ '0' => 0 ],
	[ '1+1' => 2 ],
	[ 'a+b' => 3 ],
	[ 'c*d' => 12 ],
	[ 'd*4.00' => 16 ],
	[ 'round(e, c)' => 12.346 ],
	[ 'a >= 1' => 1 ],
	[ 'b > a' => 1 ],
	[ 'c > b > a' => 1 ],
	[ 'b > a > c' => 0 ],
	[ 'a < c > b' => 1 ],
	[ '3*((2.4-.1)*a-(a)-.1*5.6+1)/round(1.234,0)' => 5.22 ],
	[ 'foo_bar.sku = 03' => 1 ],
	[ 'IF(b<=a,round(round(e,3),2),foo_bar.sku)' => '03' ],
	[ 'ambiguous > 9 and ambiguous < "1_"' => 1 ], # "010" interpreted correctly as both number and string
#	[ '(a < (b,5))' => 1 ],
#	[ "c \x{2265} (b+1.0,a,24X,-1,c)" => 1],
#	[ 'c >= (b+1.0,a,1,3.01,c)' => 0],
	[ 'a and not b' => 0 ],
	[ 'a and not n' => 1 ],
	[ 'if(a, "bar\'\'$\)(*&^%$#@!", "foo")' => q|bar''$\)(*&^%$#@!| ],
);

my %vars= (
	a => 1,
	b => 2,
	c => 3,
	d => 4,
	e => 12.3456789,
	'foo_bar.sku' => '03',
	n => 0,
	'ambiguous' => '010',
);

my $fe= Language::FormulaEngine->new;
for (@tests) {
	my ($expr, $value, $err)= @$_;
	subtest "\"$expr\"" => sub {
		is( $fe->evaluate($expr, \%vars), $value, 'evaluate' )
			or diag $fe->parser->parse_tree;
		is( $fe->compile($expr)->(\%vars), $value, 'compile/execute' )
			or diag $fe->compiler->code_body;
		done_testing;
	};
}

done_testing;
