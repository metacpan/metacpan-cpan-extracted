#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use Genealogy::Gedcom::Date;

use Test::More;

# ------------------------------------------------

my(@candidates) =
(
	{	# 1
		date   => 'French r 1950',
		result => [{canonical => '@#dFRENCH R@ 1950', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', kind => 'Date', type => 'French r', month => 'Vend', year => '1950'}],
	},
	{
		date   => 'French r Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', kind => 'Date', type => 'French r', month => 'Vend', year => '1950'}],
	},
	{
		date   => '21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', kind => 'Date', type => 'French r', day => 21, month => 'Vend', year => '1950'}],
	},
	{
		date   => 'French r 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', kind => 'Date', type => 'French r', day => 21, month => 'Vend', year => '1950'}],
	},
	{
		date   => 'Abt French r 1950',
		result => [{canonical => '@#dFRENCH R@ 1950', flag => 'ABT', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Abt Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'ABT', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Abt French r Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'ABT', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Abt 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'ABT', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{	# 10
		date   => 'Abt French r 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'ABT', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Abt French r 1950 BC',
		result => [{canonical => '@#dFRENCH R@ 1950 BC', bce => 'BC', flag => 'ABT', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Aft French r 1950',
		result => [{canonical => '@#dFRENCH R@ 1950', flag => 'AFT', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Aft Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'AFT', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Aft French r Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'AFT', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Aft 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'AFT', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Aft French r 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'AFT', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Aft French r 1950 bc',
		result => [{canonical => '@#dFRENCH R@ 1950 bc', bce => 'bc', flag => 'AFT', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Bef French r 1950',
		result => [{canonical => '@#dFRENCH R@ 1950', flag => 'BEF', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Bef Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'BEF', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{	# 20
		date   => 'Bef French r Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'BEF', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Bef 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'BEF', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Bef French r 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'BEF', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Bef French r 1950 BCE',
		result => [{canonical => '@#dFRENCH R@ 1950 BCE', bce => 'BCE', flag => 'BEF', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Bet French r 1950 and 1956',
		result =>
		[
			{canonical => '@#dFRENCH R@ 1950', flag => 'BET', kind => 'Date', type => 'French r', year => '1950'},
			{canonical => '1956', flag => 'AND', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{
		date   => 'Bet 1950 and French r 1956',
		result =>
		[
			{canonical => '1950', flag => 'BET', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '@#dFRENCH R@ 1956', flag => 'AND', kind => 'Date', type => 'French r', year => '1956'},
		],
	},
	{
		date   => 'Bet French r 1950 and French r 1956',
		result =>
		[
			{canonical => '@#dFRENCH R@ 1950', flag => 'BET', kind => 'Date', type => 'French r', year => '1950'},
			{canonical => '@#dFRENCH R@ 1956', flag => 'AND', kind => 'Date', type => 'French r', year => '1956'},
		],
	},
	{
		date   => 'Bet Gregorian 1950 and French r 1956',
		result =>
		[
			{canonical => '1950', flag => 'BET', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '@#dFRENCH R@ 1956', flag => 'AND', kind => 'Date', type => 'French r', year => '1956'},
		],
	},
	{
		date   => 'Bet French r 1950 and Gregorian 1956',
		result =>
		[
			{canonical => '@#dFRENCH R@ 1950', flag => 'BET', kind => 'Date', type => 'French r', year => '1950'},
			{canonical => '1956', flag => 'AND', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{
		date   => 'Bet 1501/01 and French r 1510',
		result =>
		[
			{canonical => '1501/01', flag => 'BET', kind => 'Date', suffix => '01', type => 'Gregorian', year => '1501'},
			{canonical => '@#dFRENCH R@ 1510', flag => 'AND', kind => 'Date', type => 'French r', year => '1510'},
		],
	},
	{	# 30
		date   => 'Bet French r 1501 and 1510/02',
		result =>
		[
			{canonical => '@#dFRENCH R@ 1501', flag => 'BET', kind => 'Date', type => 'French r', year => '1501'},
			{canonical => '1510/02', flag => 'AND', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1510'},
		],
	},
	{
		date   => 'Cal French r 1950',
		result => [{canonical => '@#dFRENCH R@ 1950', flag => 'CAL', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Cal Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'CAL', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Cal French r Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'CAL', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Cal 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'CAL', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Cal French r 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'CAL', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Cal French r 1950 bce',
		result => [{canonical => '@#dFRENCH R@ 1950 bce', bce => 'bce', flag => 'CAL', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Est French r 1950',
		result => [{canonical => '@#dFRENCH R@ 1950', flag => 'EST', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Est Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'EST', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Est French r Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'EST', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{	# 40
		date   => 'Est 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Est French r 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Est French r 1950 bc',
		result => [{canonical => '@#dFRENCH R@ 1950 bc', bce => 'bc', flag => 'EST', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Est French r 1950',
		result => [{canonical => '@#dFRENCH R@ 1950', flag => 'EST', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Est Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'EST', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Est French r Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'EST', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Est 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Est French r 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Est French r 1950 bc',
		result => [{canonical => '@#dFRENCH R@ 1950 bc', bce => 'bc', flag => 'EST', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'From French r 1950',
		result => [{canonical => '@#dFRENCH R@ 1950', flag => 'FROM', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{	# 50
		date   => 'From Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'FROM', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'From French r Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'FROM', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'From 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'FROM', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'From French r 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'FROM', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'From French r 1950 bc',
		result => [{canonical => '@#dFRENCH R@ 1950 bc', bce => 'bc', flag => 'FROM', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'To French r 1950',
		result => [{canonical => '@#dFRENCH R@ 1950', flag => 'TO', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{
		date   => 'To Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'TO', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'To French r Vend 1950',
		result => [{canonical => '@#dFRENCH R@ Vend 1950', flag => 'TO', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'To French r 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'TO', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'To French r 1950 bc',
		result => [{canonical => '@#dFRENCH R@ 1950 bc', bce => 'bc', flag => 'TO', kind => 'Date', type => 'French r', year => '1950'}],
	},
	{	# 60
		date   => 'From 1901/02 to French r 1903',
		result =>
		[
			{canonical => '1901/02', flag => 'FROM', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1901'},
			{canonical => '@#dFRENCH R@ 1903', flag => 'TO', kind => 'Date', type => 'French r', year => '1903'},
		],
	},
	{
		date   => 'From Gregorian 1901/02 to French r 1903',
		result =>
		[
			{canonical => '1901/02', flag => 'FROM', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1901'},
			{canonical => '@#dFRENCH R@ 1903', flag => 'TO', kind => 'Date', type => 'French r', year => '1903'},
		],
	},
	{
		date   => 'From French r 1901 to Gregorian 1903/04',
		result =>
		[
			{canonical => '@#dFRENCH R@ 1901', flag => 'FROM', kind => 'Date', type => 'French r', year => '1901'},
			{canonical => '1903/04', flag => 'TO', kind => 'Date', suffix => '04', type => 'Gregorian', year => '1903'},
		],
	},
	{
		date   => 'From 1950 to French r 1956',
		result =>
		[
			{canonical => '1950', flag => 'FROM', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '@#dFRENCH R@ 1956', flag => 'TO', kind => 'Date', type => 'French r', year => '1956'},
		],
	},
	{
		date   => 'Int French r 1950 (Approx)',
		result => [{canonical => '@#dFRENCH R@ 1950 (Approx)', flag => 'INT', kind => 'Date', phrase => '(Approx)', type => 'French r', year => '1950'}],
	},
	{
		date   => 'To 21 Vend 1950',
		result => [{canonical => '@#dFRENCH R@ 21 Vend 1950', day => 21, flag => 'TO', kind => 'Date', month => 'Vend', type => 'French r', year => '1950'}],
	},
	{
		date   => 'Bet French r 1501 and Julian 1510',
		result =>
		[
			{canonical => '@#dFRENCH R@ 1501', flag => 'BET', kind => 'Date', type => 'French r', year => '1501'},
			{canonical => '@#dJULIAN@ 1510', flag => 'AND', kind => 'Date', type => 'Julian', year => '1510'},
		],
	},
	{
		date   => 'From French r 1501 to Julian 1510',
		result =>
		[
			{canonical => '@#dFRENCH R@ 1501', flag => 'FROM', kind => 'Date', type => 'French r', year => '1501'},
			{canonical => '@#dJULIAN@ 1510', flag => 'TO', kind => 'Date', type => 'Julian', year => '1510'},
		],
	},
	{
		date   => 'From Julian 1950 to French r 1956',
		result =>
		[
			{canonical => '@#dJULIAN@ 1950', flag => 'FROM', kind => 'Date', type => 'Julian', year => '1950'},
			{canonical => '@#dFRENCH R@ 1956', flag => 'TO', kind => 'Date', type => 'French r', year => '1956'},
		],
	},
	{
		date   => 'Int French r 1950 (Approx)',
		result => [{canonical => '@#dFRENCH R@ 1950 (Approx)', flag => 'INT', kind => 'Date', phrase => '(Approx)', type => 'French r', year => '1950'}],
	},
	{	# 70
		date   => 'Int French r Frim 1950 (Approx)',
		result => [{canonical => '@#dFRENCH R@ Frim 1950 (Approx)', flag => 'INT', kind => 'Date', month => 'Frim', phrase => '(Approx)', type => 'French r', year => '1950'}],
	},
	{	# 71
		date   => 'Int French r Frim,1950 (Comma in date discarded, but preserved here)',
		result => [{canonical => '@#dFRENCH R@ Frim 1950 (Comma in date discarded, but preserved here)', flag => 'INT', kind => 'Date', month => 'Frim', phrase => '(Comma in date discarded, but preserved here)', type => 'French r', year => '1950'}],
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
