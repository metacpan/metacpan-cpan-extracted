#! /usr/bin/env perl
use Test2::V0;
use Try::Tiny;
use Data::Dumper;

require Language::FormulaEngine::Parser;
require Language::FormulaEngine::Namespace::Default;

my %_escape_mapping= ("\0" => '\0', "\n" => '\n', "\r" => '\r', "\t" => '\t', "\f" => '\f', "\b" => '\b', "\a" => '\a', "\e" => '\e', "\\" => '\\' );
sub escape_char { exists $_escape_mapping{$_[0]}? $_escape_mapping{$_[0]} : sprintf((ord $_[0] <= 0xFF)? "\\x%02X" : "\\x{%X}", ord $_[0]); }
sub escape_str { my $str= shift; $str =~ s/([^\x20-\x7E])/escape_char($1)/eg; $str; }

sub test_parser {
	my @tests= (
		[ 'known',
			42
		],
		[ 'unknown',
			'unknown',
		],
		[ 'known * unknown',
			'mul( 42, unknown )',
		],
		[ 'known > 5',
			1
		],
		[ 'known or unknown',
			1
		],
		[ '(known and (1 or unknown))',
			1
		],
		[ 'known * 0 * rand()',
			0
		],
		[ 'rand() * known',
			'mul( 42, rand() )'
		],
	);
	
	my $parser= Language::FormulaEngine::Parser->new;
	my $namespace= Language::FormulaEngine::Namespace::Default->new(
		variables => { known => 42 }
	);
	for (@tests) {
		my ($str, $simplified, $s_fnset, $s_varset)= @$_;
		my $parse_tree= $parser->parse($str) or die "parse($str)";
		my $simplified_tree= $parse_tree->simplify($namespace) or die "simplify($parse_tree)";
		is( $parser->deparse( $simplified_tree ), $simplified, $str );
	}
	
	done_testing;
}

test_parser();
