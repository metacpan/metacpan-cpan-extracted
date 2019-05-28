#! /usr/bin/env perl
use Test2::V0;
use Try::Tiny;
use Language::FormulaEngine;

my @tests= (
	[ 'foo+5',
		q|( $vars->{"foo"} + 5 )|
	],
	[ 'Round(3.5154321, 6)',
		q|Language::FormulaEngine::Namespace::Default::fn_round(3.5154321,6)|
	],
	[ 'foo+1*baz+bar/6/7/8',
		q|( $vars->{"foo"} + ( 1 * $vars->{"baz"} ) + ( ( ( $vars->{"bar"} / 6 ) / 7 ) / 8 ) )|
	],
	[ 'IF(b<=a,round(round(e,3),2),foo_bar.sku)',
		q|( Language::FormulaEngine::Namespace::Default::fn_compare($vars->{"b"},"<=",$vars->{"a"})?|
		.q| Language::FormulaEngine::Namespace::Default::fn_round(|
		.q|Language::FormulaEngine::Namespace::Default::fn_round($vars->{"e"},3),2)|
		.q| : $vars->{"foo_bar.sku"} )|
	],
	[ 'a and not b',
		q|( ($vars->{"a"} and ($vars->{"b"}? 0 : 1))? 1 : 0)|,
	],
	[ 'IF(1, "a", "$b")',
		q|( 1? "a" : "\x24b" )|,
	],
);

my $fe= Language::FormulaEngine->new;
for (@tests) {
	my ($str, $code, $err_regex)= @$_;
	subtest qq{"$str"} => sub {
		ok( my $tree= $fe->parser->parse($str), 'parse succeeded' ) or diag $fe->parser->error;
		if (defined $code) {
			ok( (my $gencode= $fe->compiler->perlgen($tree)), 'compile succeeded' );
			is( $gencode, $code, 'correct code generated' );
		}
		else {
			my $gencode;
			like( dies { $gencode= $fe->compiler->perlgen($tree) }, $err_regex, 'correct error message' )
				or diag $gencode;
		}
		done_testing;
	};
}

done_testing;
