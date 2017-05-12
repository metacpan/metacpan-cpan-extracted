#!/usr/bin/env perl

use strict;
use warnings;

use MarpaX::Languages::Perl::PackUnpack ':constants';

use Test::More;

# -------------

my($parser) = MarpaX::Languages::Perl::PackUnpack -> new(options => nothing_is_fatal);
my(@text)   =
(
	q|j|,
	q|s!10|,
	q|s< l<|,
	q|s![*]|,
	q|C0 U4|,
	q|%32 W*|,
	q|j<![10]|,
	q|a3/A A*|,
	q|( s l )<|,
	q|n/a* w/a2|,
	q|d[ x![ d]]|,
	q|@1 A ( ( @2 A ) @3 A )|,
	qq|s10 # Comment and newline inside template
j10|,
);
my($count) = 0;

my($result, $retrieved);

for my $text (@text)
{
	$count += 2;

	$result = $parser -> parse($text);

	ok($result == 0, "Parsed:    $text");

	$retrieved = $parser -> template_report;
	$text      = 's10 j10' if ($text =~ /^s10/);

	ok($text eq $retrieved, "Retrieved: $text");
}

done_testing($count);
