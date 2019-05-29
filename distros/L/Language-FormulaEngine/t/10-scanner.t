#! /usr/bin/env perl
use Test2::V0 -target => 'Language::FormulaEngine::Parser';
use Try::Tiny;

# capture error message of code that should die
sub error_of(&) { my $sub= shift; try { $sub->(); 'No Exception Thrown' } catch { $_ } }

my %_str_escapes= ("\0" => '\0', "\n" => '\n', "\r" => '\r', "\t" => '\t', "\f" => '\f', "\b" => '\b', "\a" => '\a', "\e" => '\e', "\\" => '\\' );
sub str_escape_char { exists $_str_escapes{$_[0]}? $_str_escapes{$_[0]} : sprintf((ord $_[0] <= 0xFF)? "\\x%02X" : "\\x{%X}", ord $_[0]); }
sub str_escape { my $str= shift; $str =~ s/([^\x20-\x7E])/str_escape_char($1)/eg; $str; }

sub test_scanner {
	my @tests= (
		[ ''
		],
		[ " \t\r\n\t   \r\n"
		],
		[ "foo",
			[ Identifier => 'foo', 0, 0 ],
		],
		[ "foo bar",
			[ Identifier => 'foo', 0, 0 ],
			[ Identifier => 'bar', 0, 4 ],
		],
		[ "1.57e-28+34",
			[ Number => 1.57e-28, 0, 0 ],
			[ '+'    => '+',      0, 8 ],
			[ Number => 34,       0, 9 ],
		],
		[ "1 A_1e-5,foOO(bar,34,baz)",
			[ Number     => '1',      0, 0 ],
			[ Identifier => 'A_1e',   0, 2 ],
			[ '-'        => '-',      0, 6 ],
			[ Number     => 5,        0, 7 ],
			[ ','        => ',',      0, 8 ],
			[ Identifier => 'foOO',   0, 9 ],
			[ '('        => '(',      0, 13 ],
			[ Identifier => 'bar',    0, 14 ],
			[ ','        => ',',      0, 17 ],
			[ Number     => 34,       0, 18 ],
			[ ','        => ',',      0, 20 ],
			[ Identifier => 'baz',    0, 21 ],
			[ ')'        => ')',      0, 24 ],
		],
		[ ">=<=>>==!===<>\x{2260}\x{2264}\x{2265}",
			[ '>=' => '>=', 0, 0 ],
			[ '<=' => '<=', 0, 2 ],
			[ '>'  => '>',  0, 4 ],
			[ '>=' => '>=', 0, 5 ],
			[ '==' => '=',  0, 7 ],
			[ '!=' => '!=', 0, 8 ],
			[ '==' => '==', 0, 10 ],
			[ '!=' => '<>', 0, 12 ],
			[ '!=' => "\x{2260}", 0, 14 ],
			[ '<=' => "\x{2264}", 0, 15 ],
			[ '>=' => "\x{2265}", 0, 16 ],
		],
		[ '(a, b, c)',
			[ '(' => '(',   0, 0 ],
			[ Identifier => 'a', 0, 1 ],
			[ ',' => ',',   0, 2 ],
			[ Identifier => 'b', 0, 4 ],
			[ ',' => ',',   0, 5 ],
			[ Identifier => 'c', 0, 7 ],
			[ ')' => ')',   0, 8 ],
		],
		[ q{ "foo"'foo'"foo\" },
			[ String => 'foo',   0, 1 ],
			[ String => 'foo',   0, 6 ],
			[ String => 'foo\\', 0, 11 ],
		],
		[ q{ f(0x40,0xfE) },
			[ Identifier =>  'f', 0,  1 ],
			[ '('        =>  '(', 0,  2 ],
			[ Number     => 0x40, 0,  3 ],
			[ ','        =>  ',', 0,  7 ],
			[ Number     => 0xfE, 0,  8 ],
			[ ')'        =>  ')', 0, 12 ],
		],
	);

	for (@tests) {
		my ($str, @tokens)= @$_;
		subtest '"'.str_escape($str).'"' => sub {
			my $p= CLASS->new();
			$p->{input}= $str;
			$p->next_token;
			my $i= 1;
			for (@tokens) {
				is( $p->token_type,  $_->[0], "token $i type '$_->[0]'" );
				is( $p->token_value, $_->[1], "token $i value" );
				my $col= $p->token_pos;
				is( $col, $_->[3], "token $i col" );
				is( $p->consume_token, $_->[1] );
				$i++;
			}
			is( $p->token_type, '0' );
			like( error_of {; $p->consume_token; }, qr/EOF/, 'consume at eof dies' );
			done_testing;
		};
	}
	done_testing;
}

test_scanner();
