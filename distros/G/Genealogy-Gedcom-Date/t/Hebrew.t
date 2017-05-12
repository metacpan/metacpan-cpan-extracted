#!/usr/bin/env perl

use strict;
use utf8;
use warnings qw(FATAL utf8); # Fatalize encoding glitches

use Genealogy::Gedcom::Date;

use Test::More;

# ------------------------------------------------

my(@candidates) =
(
	{	# 1
		date   => 'Hebrew 1950',
		result => [{canonical => '@#dHEBREW@ 1950', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', kind => 'Date', type => 'Hebrew', month => 'Tsh', year => '1950'}],
	},
	{
		date   => 'Hebrew Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', kind => 'Date', type => 'Hebrew', month => 'Tsh', year => '1950'}],
	},
	{
		date   => '21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', kind => 'Date', type => 'Hebrew', day => 21, month => 'Tsh', year => '1950'}],
	},
	{
		date   => 'Hebrew 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', kind => 'Date', type => 'Hebrew', day => 21, month => 'Tsh', year => '1950'}],
	},
	{
		date   => 'Abt Hebrew 1950',
		result => [{canonical => '@#dHEBREW@ 1950', flag => 'ABT', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Abt Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'ABT', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Abt Hebrew Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'ABT', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Abt 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'ABT', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{	# 10
		date   => 'Abt Hebrew 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'ABT', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Abt Hebrew 1950 BC',
		result => [{canonical => '@#dHEBREW@ 1950 BC', bce => 'BC', flag => 'ABT', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Aft Hebrew 1950',
		result => [{canonical => '@#dHEBREW@ 1950', flag => 'AFT', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Aft Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'AFT', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Aft Hebrew Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'AFT', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Aft 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'AFT', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Aft Hebrew 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'AFT', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Aft Hebrew 1950 BCE',
		result => [{canonical => '@#dHEBREW@ 1950 BCE', bce => 'BCE', flag => 'AFT', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Bef Hebrew 1950',
		result => [{canonical => '@#dHEBREW@ 1950', flag => 'BEF', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Bef Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'BEF', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{	# 20
		date   => 'Bef Hebrew Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'BEF', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Bef 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'BEF', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Bef Hebrew 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'BEF', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Bef Hebrew 1950 B.C.',
		result => [{canonical => '@#dHEBREW@ 1950 B.C.', bce => 'B.C.', flag => 'BEF', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Bet Hebrew 1950 and 1956',
		result =>
		[
			{canonical => '@#dHEBREW@ 1950', flag => 'BET', kind => 'Date', type => 'Hebrew', year => '1950'},
			{canonical => '1956', flag => 'AND', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{
		date   => 'Bet 1950 and Hebrew 1956',
		result =>
		[
			{canonical => '1950', flag => 'BET', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '@#dHEBREW@ 1956', flag => 'AND', kind => 'Date', type => 'Hebrew', year => '1956'},
		],
	},
	{
		date   => 'Bet Hebrew 1950 and Hebrew 1956',
		result =>
		[
			{canonical => '@#dHEBREW@ 1950', flag => 'BET', kind => 'Date', type => 'Hebrew', year => '1950'},
			{canonical => '@#dHEBREW@ 1956', flag => 'AND', kind => 'Date', type => 'Hebrew', year => '1956'},
		],
	},
	{
		date   => 'Bet Gregorian 1950 and Hebrew 1956',
		result =>
		[
			{canonical => '1950', flag => 'BET', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '@#dHEBREW@ 1956', flag => 'AND', kind => 'Date', type => 'Hebrew', year => '1956'},
		],
	},
	{
		date   => 'Bet Hebrew 1950 and Gregorian 1956',
		result =>
		[
			{canonical => '@#dHEBREW@ 1950', flag => 'BET', kind => 'Date', type => 'Hebrew', year => '1950'},
			{canonical => '1956', flag => 'AND', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{
		date   => 'Bet 1501/01 and Hebrew 1510',
		result =>
		[
			{canonical => '1501/01', flag => 'BET', kind => 'Date', suffix => '01', type => 'Gregorian', year => '1501'},
			{canonical => '@#dHEBREW@ 1510', flag => 'AND', kind => 'Date', type => 'Hebrew', year => '1510'},
		],
	},
	{	# 30
		date   => 'Bet Hebrew 1501 and 1510/02',
		result =>
		[
			{canonical => '@#dHEBREW@ 1501', flag => 'BET', kind => 'Date', type => 'Hebrew', year => '1501'},
			{canonical => '1510/02', flag => 'AND', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1510'},
		],
	},
	{
		date   => 'Cal Hebrew 1950',
		result => [{canonical => '@#dHEBREW@ 1950', flag => 'CAL', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Cal Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'CAL', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Cal Hebrew Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'CAL', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Cal 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'CAL', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Cal Hebrew 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'CAL', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Cal Hebrew 1950 BC',
		result => [{canonical => '@#dHEBREW@ 1950 BC', bce => 'BC', flag => 'CAL', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Est Hebrew 1950',
		result => [{canonical => '@#dHEBREW@ 1950', flag => 'EST', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Est Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'EST', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Est Hebrew Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'EST', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{	# 40
		date   => 'Est 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Est Hebrew 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Est Hebrew 1950 bc',
		result => [{canonical => '@#dHEBREW@ 1950 bc', bce => 'bc', flag => 'EST', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Est Hebrew 1950',
		result => [{canonical => '@#dHEBREW@ 1950', flag => 'EST', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Est Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'EST', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Est Hebrew Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'EST', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Est 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Est Hebrew 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Est Hebrew 1950 B.C.',
		result => [{canonical => '@#dHEBREW@ 1950 B.C.', bce => 'B.C.', flag => 'EST', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'From Hebrew 1950',
		result => [{canonical => '@#dHEBREW@ 1950', flag => 'FROM', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{	# 50
		date   => 'From Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'FROM', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'From Hebrew Tsh 1950',
		result => [{canonical => '@#dHEBREW@ Tsh 1950', flag => 'FROM', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'From 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'FROM', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'From Hebrew 21 Tsh 1950',
		result => [{canonical => '@#dHEBREW@ 21 Tsh 1950', day => 21, flag => 'FROM', kind => 'Date', month => 'Tsh', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'From Hebrew 1950 b.c.',
		result => [{canonical => '@#dHEBREW@ 1950 b.c.', bce => 'b.c.', flag => 'FROM', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'To Hebrew 1950',
		result => [{canonical => '@#dHEBREW@ 1950', flag => 'TO', kind => 'Date', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Int Hebrew 1950 (Approx)',
		result => [{canonical => '@#dHEBREW@ 1950 (Approx)', flag => 'INT', kind => 'Date', phrase => '(Approx)', type => 'Hebrew', year => '1950'}],
	},
	{
		date   => 'Int Hebrew Aav 1950 (Approx)',
		result => [{canonical => '@#dHEBREW@ Aav 1950 (Approx)', flag => 'INT', kind => 'Date', month => 'Aav', phrase => '(Approx)', type => 'Hebrew', year => '1950'}],
	},
	{	# 58
		date   => 'Int Hebrew ,Aav 1950 (Comma in date discarded, but preserved here)',
		result => [{canonical => '@#dHEBREW@ Aav 1950 (Comma in date discarded, but preserved here)', flag => 'INT', kind => 'Date', month => 'Aav', phrase => '(Comma in date discarded, but preserved here)', type => 'Hebrew', year => '1950'}],
	},
);

my($count)  = 0;
my($parser) = Genealogy::Gedcom::Date -> new;

my($date);
my($message);
my($result);

for my $item (@candidates)
{
	$count++;

	$result = $parser -> parse(date => $$item{date});

	is(@$result, @{$$item{result} }, "$count: $$item{date}");
}

done_testing;
