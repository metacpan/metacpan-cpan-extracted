#!/usr/bin/env perl

use strict;
use utf8;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Genealogy::Gedcom::Date;

use Test::More;

# ------------------------------------------------

sub process
{
	my($language, $candidates) = @_;
	my($count) = 0;

	my($compare);
	my($result);

	for my $item (@$candidates)
	{
		$count++;

		my($parser_1) = Genealogy::Gedcom::Date -> new;

		$parser_1 -> parse(date => $$item{date}[0]);

		my($error) = $parser_1 -> error;

		diag "Parsing $$item{date}[0]. $error\n" if ($error);

		my($parser_2) = Genealogy::Gedcom::Date -> new;

		$parser_2 -> parse(date => $$item{date}[1]);

		$error = $parser_2 -> error;

		diag "Parsing $$item{date}[0]. $error\n" if ($error);

		$result = $parser_1 -> compare($parser_2);

		ok($result == $$item{result}, "$count: $language: $$item{date}[0] 'v' $$item{date}[1]. Result: $result");
	}

} # End of process.

# ------------------------------------------------

my(@candidates) =
(
	{ # 1.
		date	=> [1950, 1950],
		result	=> 2,
	},
	{
		date	=> [1950, 1956],
		result	=> 1,
	},
	{
		date	=> ['Gregorian 1950', 1956],
		result	=> 1,
	},
	{
		date	=> [1950, 'Gregorian 1956'],
		result	=> 1,
	},
	{
		date	=> ['Gregorian 1950', 'Gregorian 1956'],
		result	=> 1,
	},
	{
		date	=> ['Julian 1950', 1956],
		result	=> 0,
	},
	{
		date	=> [1950, 'Julian 1956'],
		result	=> 0
	},
	{
		date	=> ['Julian 1956', 'Julian 1950'],
		result	=> 3,
	},
	{
		date	=> ['Gregorian 1950', 'Julian 1956'],
		result	=> 0,
	},
	{ # 10.
		date	=> ['1501/01', 1510],
		result	=> 1,
	},
	{
		date	=> [1511, '1510/02'],
		result	=> 3,
	},
	{
		date   => ['1501/02', '1503/04'],
		result => 1,
	},
	{
		date   => ['1501 BC', '1502'],
		result => 1,
	},
	{
		date   => ['1503', '1504 B.C.'],
		result => 3,
	},
	{
		date   => ['1505 bce', '1506 BC'],
		result => 3,
	},
);

process('English', \@candidates);

@candidates =
(
	{ # 1.
		date	=> ['21 Vend 1950', '21 Vend 1956'],
		result	=> 1,
	},
	{
		date	=> ['French r Vend 1956', 'French r Vend 1950'],
		result	=> 3,
	},
);

process('French', \@candidates);

@candidates =
(
	{ # 1.
		date	=> ['21.Mär.1950', '21.Mär.1956'],
		result	=> 1,
	},
	{
		date	=> ['German Mär.1956', 'German Mär.1950'],
		result	=> 3,
	},
);

process('German', \@candidates);

@candidates =
(
	{ # 1.
		date	=> ['21 Tsh 1950', '21 Tsh 1956'],
		result	=> 1,
	},
	{
		date	=> ['Hebrew Tsh 1956', 'Hebrew Tsh 1950'],
		result	=> 3,
	},
);

process('Hebrew', \@candidates);

done_testing;
