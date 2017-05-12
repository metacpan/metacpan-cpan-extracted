#!/usr/bin/env perl

use strict;
use warnings;

use Genealogy::Gedcom::Date;

use Test::More;

# ------------------------------------------------

my($parser) = Genealogy::Gedcom::Date -> new;

my($date);
my($in_string);
my($out_string);

# Candidate value => Result hashref.

diag 'Start testing parse(...)';

my(%datetime) =
(
	'15 Jul 1954' => [{canonical => '15 Jul 1954', kind => 'Date', type => 'Gregorian', day => 15, month => 'Jul', year => '1954'}],
,
);

my($expect);
my($result);

for my $candidate (sort keys %datetime)
{
	$result = $parser -> parse(date => $candidate);
	$expect = $datetime{$candidate};

	is(@$result, @$expect, "Testing: $candidate");
}

done_testing;
