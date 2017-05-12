#!/usr/bin/env perl

use strict;
use warnings;

use Genealogy::Gedcom::Date;

use Test::More;

# ------------------------------------------------

my(@candidates) =
(
	{	# 1
		date   => '1950',
		result => [{canonical => '1950', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Gregorian 1950',
		result => [{canonical => '1950', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Julian 1950',
		result => [{canonical => '@#dJULIAN@ 1950', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Jun 1950',
		result => [{canonical => 'Jun 1950', kind => 'Date', type => 'Gregorian', month => 'Jun', year => '1950'}],
	},
	{
		date   => 'Gregorian Jun 1950',
		result => [{canonical => 'Jun 1950', kind => 'Date', type => 'Gregorian', month => 'Jun', year => '1950'}],
	},
	{
		date   => 'Julian Jun 1950',
		result => [{canonical => '@#dJULIAN@ Jun 1950', kind => 'Date', type => 'Julian', month => 'Jun', year => '1950'}],
	},
	{
		date   => '21 Jun 1950',
		result => [{canonical => '21 Jun 1950', kind => 'Date', type => 'Gregorian', day => 21, month => 'Jun', year => '1950'}],
	},
	{
		date   => 'Gregorian 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', kind => 'Date', type => 'Gregorian', day => 21, month => 'Jun', year => '1950'}],
	},
	{
		date   => 'Julian 21 Jun 1950',
		result => [{canonical => '@#dJULIAN@ 21 Jun 1950', kind => 'Date', type => 'Julian', day => 21, month => 'Jun', year => '1950'}],
	},
	{	# 10
		date   => '1500/00',
		result => [{canonical => '1500/00', kind => 'Date', suffix => '00', type => 'Gregorian', year => '1500'}],
	},
	{
		date   => 'Gregorian 1500/00',
		result => [{canonical => '1500/00', kind => 'Date', suffix => '00', type => 'Gregorian', year => '1500'}],
	},
	{
		date   => 'Jun 1501/01',
		result => [{canonical => 'Jun 1501/01', kind => 'Date', suffix => '01', type => 'Gregorian', month => 'Jun', year => '1501'}],
	},
	{
		date   => 'Gregorian Jun 1501/01',
		result => [{canonical => 'Jun 1501/01', kind => 'Date', suffix => '01', type => 'Gregorian', month => 'Jun', year => '1501'}],
	},
	{
		date   => '21 Jun 1502/02',
		result => [{canonical => '21 Jun 1502/02', kind => 'Date', suffix => '02', type => 'Gregorian', day => 21, month => 'Jun', year => '1502'}],
	},
	{
		date   => 'Gregorian 21 Jun 1502/02',
		result => [{canonical => '21 Jun 1502/02', kind => 'Date', suffix => '02', type => 'Gregorian', day => 21, month => 'Jun', year => '1502'}],
	},
	{
		date   => '1950 BCE',
		result => [{canonical => '1950 BCE', bce => 'BCE', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Gregorian 1950 BCE',
		result => [{canonical => '1950 BCE', bce => 'BCE', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => '1950/03 BCE',
		result => [{canonical => '1950/03 BCE', bce => 'BCE', kind => 'Date', type => 'Gregorian', year => '1950/03'}],
	},
	{
		date   => 'Gregorian 1950/03 BCE',
		result => [{canonical => '1950/03 BCE', bce => 'BCE', kind => 'Date', type => 'Gregorian', year => '1950/03'}],
	},
	{	# 20
		date   => 'Abt 1950',
		result => [{canonical => '1950', flag => 'ABT', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Abt Gregorian 1950',
		result => [{canonical => '1950', flag => 'ABT', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Abt Julian 1950',
		result => [{canonical => '@#dJULIAN@ 1950', flag => 'ABT', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Abt Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'ABT', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Abt Gregorian Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'ABT', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Abt Julian Jun 1950',
		result => [{canonical => '@#dJULIAN@ Jun 1950', flag => 'ABT', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Abt 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'ABT', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Abt Gregorian 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'ABT', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Abt Julian 21 Jun 1950',
		result => [{canonical => '@#dJULIAN@ 21 Jun 1950', day => 21, flag => 'ABT', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Abt 1950/04',
		result => [{canonical => '1950/04', flag => 'ABT', kind => 'Date', suffix => '04', type => 'Gregorian', year => '1950'}],
	},
	{	# 30
		date   => 'Abt Gregorian 1950/04',
		result => [{canonical => '1950/04', flag => 'ABT', kind => 'Date', suffix => '04', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Abt 1950 BCE',
		result => [{canonical => '1950 BCE', bce => 'BCE', flag => 'ABT', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Abt Gregorian 1950 BCE',
		result => [{canonical => '1950 BCE', bce => 'BCE', flag => 'ABT', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Abt Julian 1950 bc',
		result => [{canonical => '@#dJULIAN@ 1950 bc', bce => 'bc', flag => 'ABT', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Aft 1950',
		result => [{canonical => '1950', flag => 'AFT', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Aft Gregorian 1950',
		result => [{canonical => '1950', flag => 'AFT', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Aft Julian 1950',
		result => [{canonical => '@#dJULIAN@ 1950', flag => 'AFT', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Aft Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'AFT', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Aft Gregorian Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'AFT', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Aft Julian Jun 1950',
		result => [{canonical => '@#dJULIAN@ Jun 1950', flag => 'AFT', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{	# 40
		date   => 'Aft 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'AFT', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Aft Gregorian 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'AFT', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Aft Julian 21 Jun 1950',
		result => [{canonical => '@#dJULIAN@ 21 Jun 1950', day => 21, flag => 'AFT', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Aft 1950/05',
		result => [{canonical => '1950/05', flag => 'AFT', kind => 'Date', suffix => '05', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Aft Gregorian 1950/05',
		result => [{canonical => '1950/05', flag => 'AFT', kind => 'Date', suffix => '05', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Aft 1950 BCE',
		result => [{canonical => '1950 BCE', bce => 'BCE', flag => 'AFT', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Aft Gregorian 1950 BCE',
		result => [{canonical => '1950 BCE', bce => 'BCE', flag => 'AFT', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Aft Julian 1950 BCE',
		result => [{canonical => '@#dJULIAN@ 1950 BCE', bce => 'BCE', flag => 'AFT', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Bef 1950',
		result => [{canonical => '1950', flag => 'BEF', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Bef Gregorian 1950',
		result => [{canonical => '1950', flag => 'BEF', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{	# 50
		date   => 'Bef Julian 1950',
		result => [{canonical => '@#dJULIAN@ 1950', flag => 'BEF', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Bef Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'BEF', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Bef Gregorian Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'BEF', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Bef Julian Jun 1950',
		result => [{canonical => '@#dJULIAN@ Jun 1950', flag => 'BEF', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Bef 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'BEF', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Bef Gregorian 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'BEF', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Bef Julian 21 Jun 1950',
		result => [{canonical => '@#dJULIAN@ 21 Jun 1950', day => 21, flag => 'BEF', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Bef 1950/06',
		result => [{canonical => '1950/06', flag => 'BEF', kind => 'Date', suffix => '06', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Bef Gregorian 1950/07',
		result => [{canonical => '1950/07', flag => 'BEF', kind => 'Date', suffix => '07', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Bef 1950 BCE',
		result => [{canonical => '1950 BCE', bce => 'BCE', flag => 'BEF', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{	# 60
		date   => 'Bef Gregorian 1950 BCE',
		result => [{canonical => '1950 BCE', bce => 'BCE', flag => 'BEF', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Bef Julian 1950 BCE',
		result => [{canonical => '@#dJULIAN@ 1950 BCE', bce => 'BCE', flag => 'BEF', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Bet 1950 and 1956',
		result =>
		[
			{canonical => '1950', flag => 'BET', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '1956', flag => 'AND', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{
		date   => 'Bet Gregorian 1950 and 1956',
		result =>
		[
			{canonical => '1950', flag => 'BET', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '1956', flag => 'AND', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{
		date   => 'Bet 1950 and Gregorian 1956',
		result =>
		[
			{canonical => '1950', flag => 'BET', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '1956', flag => 'AND', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{
		date   => 'Bet Gregorian 1950 and Gregorian 1956',
		result =>
		[
			{canonical => '1950', flag => 'BET', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '1956', flag => 'AND', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{
		date   => 'Bet Julian 1950 and 1956',
		result =>
		[
			{canonical => '@#dJULIAN@ 1950', flag => 'BET', kind => 'Date', type => 'Julian', year => '1950'},
			{canonical => '1956', flag => 'AND', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{
		date   => 'Bet 1950 and Julian 1956',
		result =>
		[
			{canonical => '1950', flag => 'BET', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '@#dJULIAN@ 1956', flag => 'AND', kind => 'Date', type => 'Julian', year => '1956'},
		],
	},
	{
		date   => 'Bet Julian 1950 and Julian 1956',
		result =>
		[
			{canonical => '@#dJULIAN@ 1950', flag => 'BET', kind => 'Date', type => 'Julian', year => '1950'},
			{canonical => '@#dJULIAN@ 1956', flag => 'AND', kind => 'Date', type => 'Julian', year => '1956'},
		],
	},
	{
		date   => 'Bet Gregorian 1950 and Julian 1956',
		result =>
		[
			{canonical => '1950', flag => 'BET', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '@#dJULIAN@ 1956', flag => 'AND', kind => 'Date', type => 'Julian', year => '1956'},
		],
	},
	{	# 70
		date   => 'Bet Julian 1950 and Gregorian 1956',
		result =>
		[
			{canonical => '@#dJULIAN@ 1950', flag => 'BET', kind => 'Date', type => 'Julian', year => '1950'},
			{canonical => '1956', flag => 'AND', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{
		date   => 'Bet 1501/01 and 1510',
		result =>
		[
			{canonical => '1501/01', flag => 'BET', kind => 'Date', suffix => '01', type => 'Gregorian', year => '1501'},
			{canonical => '1510', flag => 'AND', kind => 'Date', type => 'Gregorian', year => '1510'},
		],
	},
	{
		date   => 'Bet 1501/01 and Julian 1510',
		result =>
		[
			{canonical => '1501/01', flag => 'BET', kind => 'Date', suffix => '01', type => 'Gregorian', year => '1501'},
			{canonical => '@#dJULIAN@ 1510', flag => 'AND', kind => 'Date', type => 'Julian', year => '1510'},
		],
	},
	{
		date   => 'Bet 1501 and 1510/02',
		result =>
		[
			{canonical => '1501', flag => 'BET', kind => 'Date', type => 'Gregorian', year => '1501'},
			{canonical => '1510/02', flag => 'AND', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1510'},
		],
	},
	{
		date   => 'Bet Julian 1501 and 1510/02',
		result =>
		[
			{canonical => '@#dJULIAN@ 1501', flag => 'BET', kind => 'Date', type => 'Julian', year => '1501'},
			{canonical => '1510/02', flag => 'AND', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1510'},
		],
	},
	{
		date   => 'Bet 1501/02 and 1503/04',
		result =>
		[
			{canonical => '1501/02', flag => 'BET', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1501'},
			{canonical => '1503/04', flag => 'AND', kind => 'Date', suffix => '04', type => 'Gregorian', year => '1503'},
		],
	},
	{
		date   => 'Bet Gregorian 1501/02 and 1503/04',
		result =>
		[
			{canonical => '1501/02', flag => 'BET', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1501'},
			{canonical => '1503/04', flag => 'AND', kind => 'Date', suffix => '04', type => 'Gregorian', year => '1503'},
		],
	},
	{
		date   => 'Bet 1501/02 and Gregorian 1503/04',
		result =>
		[
			{canonical => '1501/02', flag => 'BET', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1501'},
			{canonical => '1503/04', flag => 'AND', kind => 'Date', suffix => '04', type => 'Gregorian', year => '1503'},
		],
	},
	{
		date   => 'Bet Gregorian 1501/02 and Gregorian 1503/04',
		result =>
		[
			{canonical => '1501/02', flag => 'BET', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1501'},
			{canonical => '1503/04', flag => 'AND', kind => 'Date', suffix => '04', type => 'Gregorian', year => '1503'},
		],
	},
	{
		date   => 'Cal 1950',
		result => [{canonical => '1950', flag => 'CAL', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{	# 80
		date   => 'Cal Gregorian 1950',
		result => [{canonical => '1950', flag => 'CAL', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Cal Julian 1950',
		result => [{canonical => '@#dJULIAN@ 1950', flag => 'CAL', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Cal Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'CAL', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Cal Gregorian Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'CAL', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Cal Julian Jun 1950',
		result => [{canonical => '@#dJULIAN@ Jun 1950', flag => 'CAL', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Cal 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'CAL', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Cal Gregorian 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'CAL', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Cal Julian 21 Jun 1950',
		result => [{canonical => '@#dJULIAN@ 21 Jun 1950', day => 21, flag => 'CAL', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Cal 1950/06',
		result => [{canonical => '1950/06', flag => 'CAL', kind => 'Date', suffix => '06', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Cal Gregorian 1950/07',
		result => [{canonical => '1950/07', flag => 'CAL', kind => 'Date', suffix => '07', type => 'Gregorian', year => '1950'}],
	},
	{	# 90
		date   => 'Cal 1950 bc',
		result => [{canonical => '1950 bc', bce => 'bc', flag => 'CAL', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Cal Gregorian 1950 bc',
		result => [{canonical => '1950 bc', bce => 'bc', flag => 'CAL', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Cal Julian 1950 bc',
		result => [{canonical => '@#dJULIAN@ 1950 bc', bce => 'bc', flag => 'CAL', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Est 1950',
		result => [{canonical => '1950', flag => 'EST', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Gregorian 1950',
		result => [{canonical => '1950', flag => 'EST', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Julian 1950',
		result => [{canonical => '@#dJULIAN@ 1950', flag => 'EST', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Est Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'EST', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Gregorian Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'EST', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Julian Jun 1950',
		result => [{canonical => '@#dJULIAN@ Jun 1950', flag => 'EST', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Est 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{	# 100
		date   => 'Est Gregorian 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Julian 21 Jun 1950',
		result => [{canonical => '@#dJULIAN@ 21 Jun 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Est 1950/06',
		result => [{canonical => '1950/06', flag => 'EST', kind => 'Date', suffix => '06', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Gregorian 1950/07',
		result => [{canonical => '1950/07', flag => 'EST', kind => 'Date', suffix => '07', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est 1950 bc',
		result => [{canonical => '1950 bc', bce => 'bc', flag => 'EST', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Gregorian 1950 bc',
		result => [{canonical => '1950 bc', bce => 'bc', flag => 'EST', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Julian 1950 BCE',
		result => [{canonical => '@#dJULIAN@ 1950 BCE', bce => 'BCE', flag => 'EST', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Est 1950',
		result => [{canonical => '1950', flag => 'EST', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Gregorian 1950',
		result => [{canonical => '1950', flag => 'EST', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Julian 1950',
		result => [{canonical => '@#dJULIAN@ 1950', flag => 'EST', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{	# 110
		date   => 'Est Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'EST', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Gregorian Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'EST', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Julian Jun 1950',
		result => [{canonical => '@#dJULIAN@ Jun 1950', flag => 'EST', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Est 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Gregorian 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Julian 21 Jun 1950',
		result => [{canonical => '@#dJULIAN@ 21 Jun 1950', day => 21, flag => 'EST', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Est 1950/06',
		result => [{canonical => '1950/06', flag => 'EST', kind => 'Date', suffix => '06', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Gregorian 1950/07',
		result => [{canonical => '1950/07', flag => 'EST', kind => 'Date', suffix => '07', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est 1950 bc',
		result => [{canonical => '1950 bc', bce => 'bc', flag => 'EST', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Est Gregorian 1950 bc',
		result => [{canonical => '1950 bc', bce => 'bc', flag => 'EST', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{	# 120
		date   => 'Est Julian 1950 BCE',
		result => [{canonical => '@#dJULIAN@ 1950 BCE', bce => 'BCE', flag => 'EST', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'From 1950',
		result => [{canonical => '1950', flag => 'FROM', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'From Gregorian 1950',
		result => [{canonical => '1950', flag => 'FROM', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'From Julian 1950',
		result => [{canonical => '@#dJULIAN@ 1950', flag => 'FROM', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'From Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'FROM', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'From Gregorian Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'FROM', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'From Julian Jun 1950',
		result => [{canonical => '@#dJULIAN@ Jun 1950', flag => 'FROM', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'From 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'FROM', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'From Gregorian 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'FROM', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'From Julian 21 Jun 1950',
		result => [{canonical => '@#dJULIAN@ 21 Jun 1950', day => 21, flag => 'FROM', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{	# 130
		date   => 'From 1950/06',
		result => [{canonical => '1950/06', flag => 'FROM', kind => 'Date', suffix => '06', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'From Gregorian 1950/07',
		result => [{canonical => '1950/07', flag => 'FROM', kind => 'Date', suffix => '07', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'From 1950 bc',
		result => [{canonical => '1950 bc', bce => 'bc', flag => 'FROM', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'From Gregorian 1950 bc',
		result => [{canonical => '1950 bc', bce => 'bc', flag => 'FROM', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'From Julian 1950 bc',
		result => [{canonical => '@#dJULIAN@ 1950 bc', bce => 'bc', flag => 'FROM', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'To 1950',
		result => [{canonical => '1950', flag => 'TO', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'To Gregorian 1950',
		result => [{canonical => '1950', flag => 'TO', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'To Julian 1950',
		result => [{canonical => '@#dJULIAN@ 1950', flag => 'TO', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'To Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'TO', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'To Gregorian Jun 1950',
		result => [{canonical => 'Jun 1950', flag => 'TO', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{	# 140
		date   => 'To Julian Jun 1950',
		result => [{canonical => '@#dJULIAN@ Jun 1950', flag => 'TO', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'To 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'TO', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'To Gregorian 21 Jun 1950',
		result => [{canonical => '21 Jun 1950', day => 21, flag => 'TO', kind => 'Date', month => 'Jun', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'To Julian 21 Jun 1950',
		result => [{canonical => '@#dJULIAN@ 21 Jun 1950', day => 21, flag => 'TO', kind => 'Date', month => 'Jun', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'To 1950/06',
		result => [{canonical => '1950/06', flag => 'TO', kind => 'Date', suffix => '06', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'To Gregorian 1950/07',
		result => [{canonical => '1950/07', flag => 'TO', kind => 'Date', suffix => '07', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'To 1950 bc',
		result => [{canonical => '1950 bc', bce => 'bc', flag => 'TO', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'To Gregorian 1950 bc',
		result => [{canonical => '1950 bc', bce => 'bc', flag => 'TO', kind => 'Date', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'To Julian 1950 bc',
		result => [{canonical => '@#dJULIAN@ 1950 bc', bce => 'bc', flag => 'TO', kind => 'Date', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'From 1950 to 1956',
		result =>
		[
			{canonical => '1950', flag => 'FROM', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '1956', flag => 'TO', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{	# 150
		date   => 'From 1901/02 to 1903',
		result =>
		[
			{canonical => '1901/02', flag => 'FROM', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1901'},
			{canonical => '1903', flag => 'TO', kind => 'Date', type => 'Gregorian', year => '1903'},
		],
	},
	{
		date   => 'From Gregorian 1901/02 to 1903',
		result =>
		[
			{canonical => '1901/02', flag => 'FROM', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1901'},
			{canonical => '1903', flag => 'TO', kind => 'Date', type => 'Gregorian', year => '1903'},
		],
	},
	{
		date   => 'From 1901/02 to Gregorian 1903',
		result =>
		[
			{canonical => '1901/02', flag => 'FROM', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1901'},
			{canonical => '1903', flag => 'TO', kind => 'Date', type => 'Gregorian', year => '1903'},
		],
	},
	{
		date   => 'From 1901/02 to Julian 1903',
		result =>
		[
			{canonical => '1901/02', flag => 'FROM', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1901'},
			{canonical => '@#dJULIAN@ 1903', flag => 'TO', kind => 'Date', type => 'Julian', year => '1903'},
		],
	},
	{
		date   => 'From Gregorian 1901/02 to Julian 1903',
		result =>
		[
			{canonical => '1901/02', flag => 'FROM', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1901'},
			{canonical => '@#dJULIAN@ 1903', flag => 'TO', kind => 'Date', type => 'Julian', year => '1903'},
		],
	},
	{
		date   => 'From 1901 to 1903/04',
		result =>
		[
			{canonical => '1901', flag => 'FROM', kind => 'Date', type => 'Gregorian', year => '1901'},
			{canonical => '1903/04', flag => 'TO', kind => 'Date', suffix => '04', type => 'Gregorian', year => '1903'},
		],
	},
	{
		date   => 'From Gregorian 1901 to 1903/04',
		result =>
		[
			{canonical => '1901', flag => 'FROM', kind => 'Date', type => 'Gregorian', year => '1901'},
			{canonical => '1903/04', flag => 'TO', kind => 'Date', suffix => '04', type => 'Gregorian', year => '1903'},
		],
	},
	{
		date   => 'From Julian 1901 to 1903/04',
		result =>
		[
			{canonical => '@#dJULIAN@ 1901', flag => 'FROM', kind => 'Date', type => 'Julian', year => '1901'},
			{canonical => '1903/04', flag => 'TO', kind => 'Date', suffix => '04', type => 'Gregorian', year => '1903'},
		],
	},
	{
		date   => 'From 1901/02 to 1903/04',
		result =>
		[
			{canonical => '1901/02', flag => 'FROM', kind => 'Date', suffix => '02', type => 'Gregorian', year => '1901'},
			{canonical => '1903/04', flag => 'TO', kind => 'Date', suffix => '04', type => 'Gregorian', year => '1903'},
		],
	},
	{
		date   => 'From Gregorian 1950 to 1956',
		result =>
		[
			{canonical => '1950', flag => 'FROM', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '1956', flag => 'TO', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{	# 160
		date   => 'From 1950 to Gregorian  1956',
		result =>
		[
			{canonical => '1950', flag => 'FROM', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '1956', flag => 'TO', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{
		date   => 'From Gregorian 1950 to Gregorian 1956',
		result =>
		[
			{canonical => '1950', flag => 'FROM', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '1956', flag => 'TO', kind => 'Date', type => 'Gregorian', year => '1956'},
		],
	},
	{
		date   => 'From 1950 to Julian 1956',
		result =>
		[
			{canonical => '1950', flag => 'FROM', kind => 'Date', type => 'Gregorian', year => '1950'},
			{canonical => '@#dJULIAN@ 1956', flag => 'TO', kind => 'Date', type => 'Julian', year => '1956'},
		],
	},
	{
		date   => 'Int 1950 (Approx)',
		result => [{canonical => '1950 (Approx)', flag => 'INT', kind => 'Date', phrase => '(Approx)', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Int Gregorian 1950 (Approx)',
		result => [{canonical => '1950 (Approx)', flag => 'INT', kind => 'Date', phrase => '(Approx)', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Int Julian Jun,1950 (Comma in date discarded, but preserved here)',
		result => [{canonical => '@#dJULIAN@ Jun 1950 (Comma in date discarded, but preserved here)', flag => 'INT', kind => 'Date', month => 'Jun', phrase => '(Comma in date discarded, but preserved here)', type => 'Julian', year => '1950'}],
	},
	{
		date   => 'Int 1950/00 (Approx)',
		result => [{canonical => '1950/00 (Approx)', flag => 'INT', kind => 'Date', phrase => '(Approx)', suffix => '00', type => 'Gregorian', year => '1950'}],
	},
	{
		date   => 'Int Gregorian 1950/00 (Approx)',
		result => [{canonical => '1950/00 (Approx)', flag => 'INT', kind => 'Date', phrase => '(Approx)', suffix => '00', type => 'Gregorian', year => '1950'}],
	},
	{	# 168
		date   => '(Unknown)',
		result => [{canonical => '(Unknown)', kind => 'Phrase', phrase => '(Unknown)', type => 'Phrase'}],
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

	is(@$result, @{$$item{result} }, "$count: English: $$item{date}");
}

done_testing;
