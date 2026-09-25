#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Mahjong;

sub id { return Game::Mahjong::Tiles::id_of($_[0]) }
sub hand { return Game::Mahjong::Hand->from_notation($_[0]) }
sub forms { my %s; return [ sort grep { !$s{$_}++ } map { $_->{form} } Game::Mahjong::Decompose::decompose(@_) ] }

plan tests => 7;

subtest 'seven pairs' => sub {
	# pairs that make no chow, so the hand is seven pairs and nothing else;
	# 11 22 33 44 55 66 77 would be four chows and a pair too, see below
	my $h = hand('11p 33p 55p 77p 99p EE SS');
	is_deeply(forms($h), [ 'seven_pairs' ], 'seven pairs, and not standard');
	my ($split) = Game::Mahjong::Decompose::decompose($h);
	is_deeply([ map { Game::Mahjong::Tiles::code_of($_) } @{ $split->{singles} } ], [ qw(p1 p3 p5 p7 p9 we ws) ], 'the pairs listed once each');
	is_deeply($split->{sets}, [], 'no sets');
	my $four = hand('3333p 55s EE SS WW NN');
	is_deeply(forms($four), [ 'seven_pairs' ], 'four of a kind is two pairs (the plan takes the common reading)');
	my ($s4) = Game::Mahjong::Decompose::decompose($four);
	is(scalar @{ $s4->{singles} }, 7, 'seven entries');
	is(scalar(grep { $_ == id('p3') } @{ $s4->{singles} }), 2, 'the four listed twice');
	my $mixed = hand('11m 99p 22s EE SS WW RR');
	is_deeply(forms($mixed), [ 'seven_pairs' ], 'pairs of anything');
	my $melded = hand('11p 22p 33p 44p 55p pung(EEE)');
	is_deeply(forms($melded), [], 'seven pairs is never melded');
	my ($won) = Game::Mahjong::Decompose::decompose($h, id('p5'));
	is_deeply($won->{placement}, { in => 'pair', index => 0, wait => 'pair' }, 'won on a pair: a pair wait');
};

subtest 'a hand that is both seven pairs and standard' => sub {
	# 22 33 44 22 33 44 55 of one suit: seven pairs, and also 234 234 234 + 55... no:
	# 2 2 3 3 4 4 5 5 6 6 7 7 8 8 is 234 345 ... let the decomposer say
	my $h = hand('22334455667788p');
	is_deeply(forms($h), [ 'seven_pairs', 'standard' ], 'seven pairs and standard splits both returned');
	my @standard = grep { $_->{form} eq 'standard' } Game::Mahjong::Decompose::decompose($h);
	ok(scalar @standard >= 1, 'at least one standard split');
};

subtest 'thirteen orphans' => sub {
	my $h = hand('19m 19p 19s ESWN RGB E');
	is_deeply(forms($h), [ 'thirteen_orphans' ], 'the thirteen with a second east');
	my ($split) = Game::Mahjong::Decompose::decompose($h);
	is($split->{pair}, id('we'), 'the pair is east');
	is(scalar @{ $split->{singles} }, 13, 'thirteen singles');
	for my $pair (qw(m1 m9 p1 p9 s1 s9 we ws ww wn dr dg dw)) {
		my $with = hand('19m 19p 19s ESWN RGB');
		$with->add(id($pair));
		is_deeply(forms($with), [ 'thirteen_orphans' ], "the pair on $pair");
	}
	my ($on_single) = Game::Mahjong::Decompose::decompose($h, id('m1'));
	is_deeply($on_single->{placement}, { in => 'single', index => 0, wait => 'single' }, 'won on a single');
	my ($on_pair) = Game::Mahjong::Decompose::decompose($h, id('we'));
	is($on_pair->{placement}{wait}, 'pair', 'won on the pair');
	is_deeply(forms(hand('19m 19p 19s ESWN RGB 5m')), [], 'a five is not an orphan');
	is_deeply(forms(hand('19m 19p 19s ESWN RGB')), [], 'thirteen tiles are not fourteen');
	is_deeply(forms(hand('1m 19p 19s ESWN RGB EE')), [], 'twelve orphans with two pairs is not the hand');
};

subtest 'honours and knitted tiles' => sub {
	# greater: all seven honours and seven suit singles from three knitted sequences
	my $g = hand('147m 258p 3s ESWN RGB');
	is_deeply(forms($g), [ 'honours_knitted' ], 'greater honours and knitted: 147m 258p 3s + seven honours');
	my ($split) = Game::Mahjong::Decompose::decompose($g);
	is(scalar @{ $split->{singles} }, 14, 'fourteen singles');
	# lesser: fewer honours, more suit tiles
	my $l = hand('147m 258p 369s ESWN R');
	is_deeply(forms($l), [ 'honours_knitted' ], 'lesser: 147m 258p 369s + five honours');
	# every assignment of sequences to suits: seven honours and seven suit singles
	is_deeply(forms(hand('258m 36p 14s ESWN RGB')), [ 'honours_knitted' ], '258m 36p 14s');
	is_deeply(forms(hand('369m 14p 25s ESWN RGB')), [ 'honours_knitted' ], '369m 14p 25s');
	is_deeply(forms(hand('147m 36p 25s ESWN RGB')), [ 'honours_knitted' ], '147m 36p 25s');
	# a partial sequence is fine, the same sequence in two suits is not
	is_deeply(forms(hand('14m 25p 369s ESWN RGB')), [ 'honours_knitted' ], 'partial sequences');
	is_deeply(forms(hand('147m 147p 369s ESWN R')), [], '1-4-7 in two suits: not knitted');
	is_deeply(forms(hand('148m 258p 369s ESWN R')), [], 'an 8 among the 1-4-7: not knitted');
	is_deeply(forms(hand('147m 258p 369s ESWN RR')), [], 'a pair of dragons: not all singles');
};

subtest 'the knitted straight' => sub {
	my $h = hand('147m 258p 369s 111m 55p');
	is($h->total, 14, 'fourteen: nine knitted, a pung and a pair');
	is_deeply(forms($h), [ 'knitted_straight' ], 'a knitted straight, and not standard');
	my ($split) = Game::Mahjong::Decompose::decompose($h);
	is(scalar(grep { $_->{kind} eq 'knit' } @{ $split->{sets} }), 3, 'three knit sets');
	is(scalar(grep { $_->{kind} eq 'pung' } @{ $split->{sets} }), 1, 'and the pung');
	is($split->{pair}, id('p5'), 'the pair');
	my @knit = sort map { Game::Mahjong::Notation::print(@{ $_->{tiles} }) } grep { $_->{kind} eq 'knit' } @{ $split->{sets} };
	is_deeply(\@knit, [ '147m', '258p', '369s' ], 'the sequences as sets');
	is_deeply(forms(hand('258m 369p 147s 234m 99p')), [ 'knitted_straight' ], 'another assignment, with a chow');
	my $melded = hand('147m 258p 369s 55m pung(EEE)');
	is_deeply(forms($melded), [ 'knitted_straight' ], 'with one meld on the table');
	is_deeply(forms(hand('147m 258p 369s 55m 6m')), [], 'nine knitted and a pair and a single is not complete');
	is_deeply(forms(hand('147m 258p 36s 111m 55p 9p')), [], 'eight of the nine is not a straight');
	my ($won) = Game::Mahjong::Decompose::decompose($h, id('m4'));
	is($won->{placement}{wait}, 'knit', 'won on a knitted tile: a knit wait');
};

subtest 'nine gates decomposes as a standard hand on every wait' => sub {
	for my $r (1 .. 9) {
		my $h = hand('1112345678999m');
		$h->add(id("m$r"));
		ok(Game::Mahjong::Decompose::is_complete($h), "complete with the $r");
		my @f = @{ forms($h) };
		ok((grep { $_ eq 'standard' } @f), "and standard among " . join(',', @f));
	}
};

subtest 'no chow runs across a suit or off the end' => sub {
	is_deeply(forms(hand('9m 12p 456p 789s 111s 55m')), [], '9m 1p 2p is not a chow');
	is_deeply(forms(hand('89m 1p 456p 789s 111s 55m')), [], '8m 9m 1p is not a chow');
	is_deeply(forms(hand('ESW 456p 789s 111s 55m')), [], 'E S W is not a chow');
	is_deeply(forms(hand('RGB 456p 789s 111s 55m')), [], 'R G B is not a chow');
};

# THE MUTATION CHECKS, named so they can be run by hand:
#   let seven pairs accept a melded hand          -> 'seven pairs is never melded' fails
#   count four of a kind as one pair              -> 'four of a kind is two pairs' fails
#   try one assignment of sequences to suits      -> '258m 369p 147s' fails
#   accept eight knitted tiles                    -> 'eight of the nine' fails
