#!/usr/bin/env perl

use strict;
use warnings;

use MarpaX::Languages::SVG::Parser;

# ---------------------------------

my(%option) =
(
	input_file_name => 'data/ellipse.01.svg',
);
my($parser) = MarpaX::Languages::SVG::Parser -> new(%option);
my($result) = $parser -> run;

die "Parse failed\n" if ($result == 1);

for my $item (@{$parser -> items -> print})
{
	print sprintf "%-16s  %-16s  %s\n", $$item{type}, $$item{name}, $$item{value};
}
