#! /usr/bin/env perl
use Test2::V0;
use Try::Tiny;
use Data::Dumper;
use Language::FormulaEngine;

my %_escape_mapping= ("\0" => '\0', "\n" => '\n', "\r" => '\r', "\t" => '\t', "\f" => '\f', "\b" => '\b', "\a" => '\a', "\e" => '\e', "\\" => '\\' );
sub escape_char { exists $_escape_mapping{$_[0]}? $_escape_mapping{$_[0]} : sprintf((ord $_[0] <= 0xFF)? "\\x%02X" : "\\x{%X}", ord $_[0]); }
sub escape_str { my $str= shift; $str =~ s/([^\x20-\x7E])/escape_char($1)/eg; $str; }

my $engine= Language::FormulaEngine->new;
$engine->compiler->output_api('function_of_vars');
$engine->namespace->variables->{zero}= 0;
$engine->namespace->variables->{fortytwo}= 42;

sub test_parser {
	my @tests= (
		[ 'x + 5 - 5 + zero',
			{ sum => 1 }, { x => 1, zero => 1 },
			'x', { }, { x => 1 },
			1
		],
		[ 'average( 3, abs(x) + sin(zero) )',
			{ abs => 1, average => 1, sin => 1, sum => 1 }, { x => 1, zero => 1 },
			'average( 3, abs( x ) )', { abs => 1, average => 1 }, { x => 1 },
			2
		],
	);
	
	for (@tests) {
		my ($expr_text, $fn_set, $var_set, $simplified_text, $s_fn_set, $s_var_set, $value)= @$_;
		subtest '"'.escape_str($expr_text).'"' => sub {
			ok( my $formula= $engine->parse($expr_text), 'parse' );
			is( "$formula", $expr_text, 'to_string' );
			is( $formula->functions, $fn_set, 'functions' );
			is( $formula->symbols, $var_set, 'symbols' );
			ok( my $simplified= $formula->simplify, 'simplify' );
			is( $simplified->deparse, $simplified_text, 'simplified deparse' );
			is( $simplified->functions, $s_fn_set, 'simplified functions' );
			is( $simplified->symbols, $s_var_set, 'simplified symbols' );
			is( $formula->evaluate(x => 1), $value, 'evaluate' );
			ok( my $sub= $formula->compile, 'compile' );
			is( $sub->(x => 1), $value, 'coderef-exec' );
			done_testing;
		};
	}
	
	done_testing;
}

test_parser();
