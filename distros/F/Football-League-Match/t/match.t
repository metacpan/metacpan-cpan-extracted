#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 11;
use Football::League::Match;

local $/;
my @matches = split "\n", <DATA>;

# invalid match 1
{
	eval { Football::League::Match->from_soccerdata($matches[0]) };
	like $@, qr/Invalid date/, "can't make new match with invalid date";
}


# invalid match 2
{
	eval { Football::League::Match->from_soccerdata($matches[1]) };
	like $@, qr/Invalid number of fields/, "can't make new match with invalid fields";
}

# valid (but imaginary!) match
{
	isa_ok my $match = Football::League::Match->from_soccerdata($matches[2]), 
		'Football::League::Match';
	is $match->final_year_of_season, 2003, "final year of season ok";
	is $match->division, 1, "Correct division (for 02/03 season at least!)";
	is $match->home_team, "Leicester", "Foxes never quit!";
	is $match->home_score, 4, "correct home score";
	is $match->away_score, 0, "correct away score";
	is $match->away_team, "NottForest", "Correct away team";
	is $match->result, "4-0", "Correct score. I wish";
	isa_ok $match->date => 'Time::Piece';
}

__DATA__
2003,"1","Leicester",4,"NottForest",0,20031340
2003,"1","Leicester",4,"NottForest",0
2003,"1","Leicester",4,"NottForest",0,20030412
