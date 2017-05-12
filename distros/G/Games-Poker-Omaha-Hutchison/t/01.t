#!/usr/bin/perl 

use strict;
use warnings;

use Test::More tests => 54;
use Games::Poker::Omaha::Hutchison;

our %expect = (
	"As Ks Ah Kh" => [ 27, 8, 17, 2 ],
	"8s 9s 9d 8d" => [ 16, 3, 9,  4 ],
	"Qs Qd 8H 8C" => [ 13, 0, 11, 2 ],
	"As Ah 7C 2D" => [ 10, 0, 9,  1 ],
	"KS KD 3s 6D" => [ 15, 6, 8,  1 ],
	"AS KD QH TS" => [ 15, 4, 0,  11 ],

	"Ah Kh Ad Qd" => [ 24, 8, 9, 7 ], 
	"2h 3c 4s 5d" => [ 2, 0, 0, 2 ],  # ??
	"2h 3c Ks Qd" => [ 6, 0, 0, 6 ],  # ??
	"Ah 2c 3s 4d" => [ 3, 0, 0, 3 ], # ??
	"Ad Kc Qh 2s" => [ 8, 0, 0, 8 ], # ??
	"Kh Jc Th 6s" => [ 9, 3, 0, 6 ], # ??

	# www.internettexasholdem.com/phpbb2/sat-aug-13-2005-743-pm-vp180454.html
	"Ad 6c As 4c" => [ 12, 1, 9, 2 ], # ??
);

while (my ($hand_str, $pts) = each %expect) {
  my $hand = Games::Poker::Omaha::Hutchison->new($hand_str);
  my ($ttl, $flush, $pairs, $str8) = @$pts;
	is $hand->flush_score, $flush,, "Flush $hand_str";
	is $hand->pair_score,     $pairs, "Pairs $hand_str";
  is $hand->straight_score, $str8,  "Straight $hand_str";
	is $hand->hand_score, $ttl, "Total $hand_str";
}


{
	my $hand = eval { Games::Poker::Omaha::Hutchison->new };
	ok $@, "Need arguments for new";
}

{
	my $hand = Games::Poker::Omaha::Hutchison->new(qw/As Ks Ah KH/); 
	is $hand->hand_score, 27, "Can pass list to constructor, too";
}

