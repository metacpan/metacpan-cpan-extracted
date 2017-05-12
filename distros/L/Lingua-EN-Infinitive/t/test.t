#!/usr/bin/env perl

use strict;
use warnings;

use Lingua::EN::Infinitive;

use Test::More;

# --------------------------------------------------------------------

my($spell) = Lingua::EN::Infinitive -> new;

my($expectedRule, $expectedStem);
my($prefix1, $prefix2);
my($rule);
my($sample, $suffix);
my($word);

while (<DATA>)
{
	next if (/^#/);

	chomp;

	$sample									= $_;
	$sample									=~ s/\t+/\t/g;
	($expectedRule, $word, $expectedStem)	= split(/\t/, $sample);
	($prefix1, $prefix2, $suffix, $rule)	= $spell -> stem($word);

	my($result, $stem) = ('ok', "$prefix1/$prefix2");

	if ( ($expectedStem ne $prefix1) && ($expectedStem ne $prefix2) )
	{
		$result = 'not ok';
	}

	ok($result eq 'ok', $sample);
}

my(%expected) =
(
	Turkish		=> 'Turkey',
	amateurish	=> 'amateur',
	cuttlefish	=> '',
	demolish	=> '',
	radish		=> '',
	swish		=> '',
	standoffish	=> 'standoffish',
	vixenish	=> 'vixen',
	whitish		=> 'white',
);

my($adjective);
my($noun);

for $adjective (qw/Turkish amateurish cuttlefish demolish radish swish vixenish whitish/)
{
	$noun = $spell -> adjective2noun($adjective);

	ok($noun eq $expected{$adjective}, "$adjective => $noun");
}


done_testing;

__DATA__
1			aches			ache
1			arches			arch
2			vases			vase
2			basses			bass
3			axes			axe
3			fixes			fix
4			hazes			haze
4			buzzes			buzz
6a			caress			caress
6b			bans			ban
7			Jones's			Jones
8			creater			creater
9			reacter			reacter
10			copier			copy
11			baker			bake
11			smaller			small
12a			curried			curry
12b			bored			bore
12b			seated			seat
# Can't handle these 2 with the special code as for the following 5 because after
# chopping the suffix, we are not left with a one-syllable word. Ie it's too hard.
# Yes, that was 5 not 7. Look for the doubled-consonant in the middle of the word.
# The special code is in Infinitive.pm @ line 1188.
#12b		bootstrapped	bootstrap
#12b		bootstrapping	bootstrap
12b			tipped			tip
12b			kitted			kit
12b			capped			cap
12b			chopped			chop
12b			curried			curry
12b			bored			bore
12b			seated			seat
13a			flies			fly
13b			palates			palate
14a			liveliest		lively
14b			wisest			wise
14b			strongest		strong
15			living			live
15			laughing		laugh
15			swaying			sway
15			catching		catch
15			smiling			smile
15			swimming		swim
15			running			run
15			floating		float
15			keyboarding		keyboard
15			wrestling		wrestle
15			traveling		travel
15			traipsing		traipse
16			stylist			style
16			dentist			dent
17			cubism			cube
17			socialism		social
18			scarcity		scarce
18			rapidity		rapid
19			immunize		immune
19			lionize			lion
20			livable			live
20			portable		port
22			nobility		noble
23			identifiable	identify
24			psychologist	psychology
25			photographic	photography
26			stylistic		stylist
27			martensitic		martensite
27			politic			polite
28			ladylike		lady
29			biologic		biology
30			battlement		battle
31			supplemental	supplement
32			thermometry		thermometer
33			inadvertence	inadvertent
34			potency			potent
35			discipleship	disciple
36			mystical		mystic
37			regional		region
37			national		nation
38			horribly		horrible
39			scantily		scanty
40			partly			part
41a			dutiful			duty
41b			harmful			harm
42a			likelihood		likely
42b			neighborhood	neighbor
42b			neighbourhood	neighbour
43a			penniless		penny
43b			listless		list
44a			heartiness		hearty
44b			coolness		cool
45			specification	specify
46			rationalization	rationalize
47			detection		detect
48			exertion		exert
49			creation		create
50			creator			create
51			detector		detect
52			creative		creation
52			decisive		decision
53			Australian		Australia
54			Jeffersonian	Jefferson
irregular	rove			reeve
irregular	dove			dive
irregular	snuck			sneak
irregular	wot				wit
