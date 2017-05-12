#!/usr/bin/env perl

use strict;
use warnings;

use MarpaX::Languages::Perl::PackUnpack ':constants';

# -----------

my($parser) = MarpaX::Languages::Perl::PackUnpack -> new(options => print_warnings);
my(@text)   =
(
	qq|n/a* # Newline
w/a2|,
	q|a3/A A*|,
	q|i9pl|,
);

my($result);

for my $text (@text)
{
	print "Parsing: $text. \n";

	$result = $parser -> parse($text);

	print join("\n", @{$parser -> tree2string}), "\n";
	print "Parse result: $result (0 is success)\n";
	print 'Template: ', $parser -> template_report, ". \n";
	print '-' x 50, "\n";
}

print "\n";
print "Size report: \n";

$parser -> size_report;
