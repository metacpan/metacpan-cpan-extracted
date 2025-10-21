#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Genealogy::Obituary::Parser qw(parse_obituary);

my $text = <<'END';
He is survived by his wife Mary, sons John and David, and grandchildren Sophie, Liam, and Ava.
His parents were George and Helen.
He also leaves behind his sister Claire.
END

my $rel = parse_obituary({ text => $text });

# diag(Data::Dumper->new([$rel])->Dump());

cmp_deeply($rel,
	{
		'spouse' => [
			{ 'name' => 'Mary', 'sex' => 'F', 'status' => 'living' }
		], 'parents' => {
			'father' => { 'name' => 'George' },
			'mother' => { 'name' => 'Helen' }
		}, 'children' => [
			{ 'name' => 'John', 'sex' => 'M' },
			{ 'name' => 'David', 'sex' => 'M' }
		], 'grandchildren' => [
			{ 'name' => 'Sophie' },
			{ 'name' => 'Liam' },
			{ 'name' => 'Ava' }
		], 'sisters' => [
			{ 'name' => 'Claire', 'status' => 'living', 'sex' => 'F' },
		]
	}
);

$text = << 'END';
Fort Wayne Journal Gazette, 3 March 1979, p.	2a.:	Burton F. Harris, Jr., 53 of 1811 High St., died at 8 p.m.	Thursday in Parkview Memorial Hospital, where he had been a patient; 1 1/2 days.	A Fort Wayne native, Mr. Harris served 21 years in the U. S. Navy, including service during World War II and the Korean War.	Surviving are one daughter, Margie Newton, Fort wayne; four sons, John, Michael, Stephen and Jerrold, all of Fort wayne; two sisters, Mrs. Betty Ramarize, Santa Barbara, Calif., and Mrs. Nancy Closer, Fort Wayne: and three brothers, Harold, Carl and Robert, all of Fort Wayne.	Friends may call at C. M. Sloan & Sons Funeral Home and from 7 to 9 p.m.	Saturday and 2 to 5 and 7 to 9 Sunday.	Services will be 10 a.m.	Monday at the funeral home, with burial in Lindenwood Cemetery
END

$rel = parse_obituary(\$text);

# diag(Data::Dumper->new([$rel])->Dump());

cmp_deeply($rel,
	{
		'sisters' => [
			 {
				 'location' => 'Santa Barbara, Calif.',
				 'sex' => 'F',
				 'spouse' => {
					 'name' => 'Ramarize',
					 'sex' => 'M'
				 },
				 'name' => 'Betty'
			 }, {
				 'name' => 'Nancy',
				 'sex' => 'F',
				 'location' => 'Fort Wayne',
				 'spouse' => {
					 'name' => 'Closer',
					 'sex' => 'M'
				 }
			 }
		 ], 'funeral' => {
			 'location' => 'the funeral home'
		 }, 'brothers' => [
			{
				'name' => 'Harold',
				'location' => 'Fort Wayne',
				'sex' => 'M'
			}, {
				'location' => 'Fort Wayne',
				'sex' => 'M',
				'name' => 'Carl'
			}, {
				'name' => 'Robert',
				'location' => 'Fort Wayne',
				'sex' => 'M'
			}
		], 'children' => [
			{
				'location' => 'Fort wayne',
				'sex' => 'M',
				'name' => 'John'
			}, {
				'name' => 'Michael',
				'sex' => 'M',
				'location' => 'Fort wayne'
			}, {
				'name' => 'Stephen',
				'sex' => 'M',
				'location' => 'Fort wayne'
			}, {
				'name' => 'Jerrold',
				'sex' => 'M',
				'location' => 'Fort wayne'
			}, {
				'name' => 'Margie',
				'sex' => 'F',
				'spouse' => {
					'name' => 'Newton',
					'sex' => 'M'
				},
				'location' => 'Fort wayne'
			}
		]
	}
);

done_testing();
