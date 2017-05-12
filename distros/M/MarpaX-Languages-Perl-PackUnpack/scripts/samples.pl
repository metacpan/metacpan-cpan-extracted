#!/usr/bin/env perl

use strict;
use warnings;

use MarpaX::Languages::Perl::PackUnpack ':constants';

# -----------

my($parser) = MarpaX::Languages::Perl::PackUnpack -> new(options => print_warnings);
my(@text)   =
(
	q|a|,
	q|a10|,
	q|a[10]|,
	q|a*|,
	q|a[*]|,
	q|s|,
	q|s!|,
	q|s!10|,
	q|s![10]|,
	q|s!*|,
	q|s![*]|,
	q|s!<|,
	q|s!>|,
	q|s!<10|,
	q|s!>10|,
	q|s!<[10]|,
	q|s!>[10]|,
	q|s<!|,
	q|s>!|,
	q|s<!10|,
	q|s>!10|,
	q|s<![10]|,
	q|s>![10]|,
	q|j|,
	q|j!|,
	q|j!10|,
	q|j![10]|,
	q|j!*|,
	q|j![*]|,
	q|j!<|,
	q|j!>|,
	q|j!<10|,
	q|j!>10|,
	q|j!<[10]|,
	q|j!>[10]|,
	q|j<!|,
	q|j>!|,
	q|j<!10|,
	q|j>!10|,
	q|j<![10]|,
	q|j>![10]|,
	q|d[x![d]]|,
	q|C0U4|,
	q|(sl)<|,
	q|(sl)<5|,
	q|(sl)5>|,
	q|a3/A A*|,
	q|n/a* w/a2|,
	q|%32 W*|,
	q|Z8 Z8 Z16 L|,
	q|sx2l|,
	qq|s10 # Comment and newline inside template
j10|,
);
my(%count) = (fail => 0, success => 0, total => 0);

my($result);

for my $text (@text)
{
	$count{total}++;

	print "$count{total}: Parsing: $text. ";

	$result = $parser -> parse($text);

	if ($result == 0)
	{
		$count{success}++;
	}

	print join("\n", @{$parser -> tree2string}), "\n";
	print "Parse result: $result (0 is success)\n";
	print 'Template: ', $parser -> template_report, "\n";
}

print "\n";

$count{fail} = $count{total} - $count{success};

for my $key (sort keys %count)
{
	print sprintf("%-7s: %3d\n", ucfirst $key, $count{$key});
}
