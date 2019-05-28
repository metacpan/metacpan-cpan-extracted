#! /usr/bin/env perl
use Test2::V0 -target => 'Language::FormulaEngine::Parser';
use Try::Tiny;
use Data::Dumper;

my %_escape_mapping= ("\0" => '\0', "\n" => '\n', "\r" => '\r', "\t" => '\t', "\f" => '\f', "\b" => '\b', "\a" => '\a', "\e" => '\e', "\\" => '\\' );
sub escape_char { exists $_escape_mapping{$_[0]}? $_escape_mapping{$_[0]} : sprintf((ord $_[0] <= 0xFF)? "\\x%02X" : "\\x{%X}", ord $_[0]); }
sub escape_str { my $str= shift; $str =~ s/([^\x20-\x7E])/escape_char($1)/eg; $str; }

sub test_parser {
	my @tests= (
		[ 'foo',
			'foo'
		],
		[ 'foo_1.2.3',
			'foo_1.2.3',
		],
		[ 'foo*bar+baz/blah',
			'sum( mul( foo, bar ), div( baz, blah ) )'
		],
		[ '5 > 6 > 7',
			"compare( 5, '>', 6, '>', 7 )"
		],
		[ 'foo > bar+1-5-foo =baz*1e-2',
			"compare( foo, '>', sum( bar, 1, -5, negative( foo ) ), '==', mul( baz, 0.01 ) )"
		],
		[ 'foo((((34))))',
			"foo( 34 )"
		],
		[ 'foo()',
			"foo()"
		],
		[ 'foo(12,34)(54,32)',
			undef, qr/unexpected.*\(/i
		],
		[ '',
			undef, qr/expected.*near.*end of/i
		],
		[ '3foo',
			undef, qr/unknown.*syntax/i
		],
		[ '(a,b,c)',
			"list( a, b, c )"
		],
		[ '(a,\'bar\',"foo")',
			"list( a, 'bar', 'foo' )"
		],
	);
	
	for (@tests) {
		my ($str, $canonical, $err_regex)= @$_;
		subtest '"'.escape_str($str).'"' => sub {
			my $parser= CLASS->new;
			$parser->parse($str);
			
			if (defined $canonical) {
				is( $parser->error, undef, 'no error' );
				is( $parser->parse_tree && $parser->deparse, $canonical, 'correct interpretation' )
					or diag Dumper($parser);
			}
			else {
				is( $parser->parse_tree, undef, 'parse failed' );
				like( $parser->error, $err_regex, 'correct error message' )
					or diag Dumper($parser);
			}
			done_testing;
		};
	}
	
	done_testing;
}

test_parser();
