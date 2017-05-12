#!/usr/bin/env perl

use strict;
use warnings;

use MarpaX::Languages::Perl::PackUnpack ':constants';

# -----------

my($parser) = MarpaX::Languages::Perl::PackUnpack -> new(options => print_warnings);
my(@text)   =
(
	q|(sl)<|,
	q|%32 W*|,
	q|a3/A A*|,
	q|d[x![d]]|,
);
my($format) = "%-20s  %-20s  %-10s  %-10s\n";

my($attributes);
my($lexeme);
my($result);
my($text);

for my $text (@text)
{
	print "Parsing: $text. \n";
	print sprintf($format, 'Node name', 'Lexeme name', 'Depth', 'Text');

	$result = $parser -> parse($text);

	for my $node ($parser -> tree -> traverse)
	{
		next if ($node -> is_root);

		$attributes = $node -> meta;
		$lexeme     = $$attributes{lexeme};
		$text       = $$attributes{text};

		print sprintf($format, $node -> value, $lexeme, $node -> depth, $text);
	}

	print '-' x 66, "\n";
}
