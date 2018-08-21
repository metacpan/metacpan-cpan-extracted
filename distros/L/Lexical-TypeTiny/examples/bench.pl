#!/usr/bin/env perl

use strict;
use warnings;
use Benchmark qw(cmpthese);

use Types::Standard qw(Str);
use Lexical::TypeTiny;
use Type::Tie;

cmpthese -1, {
	LexicalType => sub {
		my Str $foo = 0; $foo++ for 0..1000;
	},
	TypeTie => sub {
		tie my $foo, Str; $foo = 0; $foo++ for 0..1000;
	},
	Nothing => sub {
		my $foo = 0; $foo++ for 0..1000;
	},
};
__END__
               Rate     TypeTie LexicalType     Nothing
TypeTie       583/s          --        -77%        -99%
LexicalType  2489/s        327%          --        -95%
Nothing     47287/s       8004%       1800%          --
