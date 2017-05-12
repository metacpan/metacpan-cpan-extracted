#!/usr/bin/perl
use warnings;
use strict;

use Games::Baseball::Scorecard;

# This is a game from tonight, and I kept score in text mode instead of
# manually with paper.  I still like paper better.  But this is interesting.

# http://boston.redsox.mlb.com/NASApp/mlb/news/boxscore.jsp?gid=2005_09_16_oakmlb_bosmlb_1
# http://sports.espn.go.com/mlb/boxscore?gameId=250916102

my $s = Games::Baseball::Scorecard->new;
#$s->debug(2);

$s->init({
	scorer	=> 'Pudge',
	date	=> '2005-09-15, 20:42-23:49',
	at	=> 'Fenway Park, Boston',
	att	=> '35,249',
	temp	=> '65 rain',
	wind	=> '6 from RF',
	home	=> {
		team	=> 'Boston Red Sox',
		starter	=> 49,
		roster	=> {
			23 => 'Cora, Alex',
			18 => 'Damon, Johnny',
			10 => 'Graffanino, Tony',
			25 => 'Hyzdu, Adam',
			44 => 'Kapler, Gabe',
			40 => 'Machado, Alejandro',
			15 => 'Millar, Kevin',
			28 => 'Mirabelli, Doug',
			11 => 'Mueller, Bill',
			 7 => 'Nixon, Trot',
			19 => 'Olerud, John',
			34 => 'Ortiz, David',
			13 => 'Petagine, Roberto',
			24 => 'Ramirez, Manny',
			 3 => 'Renteria, Edgar',
			48 => 'Shoppach, Kelly',
			39 => 'Stern, Adam',
			33 => 'Varitek, Jason',
			20 => 'Youkilis, Kevin',

			61 => 'Arroyo, Bronson',
			53 => 'Bradford, Chad',
			30 => 'Clement, Matt',
			57 => 'Delcarmen, Manny',
			55 => 'DiNardo, Lenny',
			29 => 'Foulke, Keith',
			54 => 'Gonzalez, Jeremi',
			43 => 'Harville, Chad',
			36 => 'Myers, Mike',
			58 => 'Papelbon, Jonathan',
			46 => 'Perisho, Matt',
			38 => 'Schilling, Curt',
			50 => 'Timlin, Mike',
			49 => 'Wakefield, Tim',
			16 => 'Wells, David',
		},
		lefties => [
			16, 36, 55
		],
		lineup	=> [
			[18, 8],
			[ 3, 6],
			[34, 0],
			[24, 7],
			[15, '9/3'],
			[20, 3],
			[28, 2],
			[11, 5],
			[10, 4],
		],
	},
	away	=> {
		team	=> 'Oakland Athletics',
		starter	=> 37,
		roster	=> {
			26 => 'Bocachica, Hiram',
			49 => 'Byrnum, Freddie',
			22 => 'Castillo, Alberto',
			 3 => 'Chavez, Eric',
			14 => 'Ellis, Mark',
			 6 => 'Ginter, Keith',
			10 => 'Hatteberg, Scott',
			11 => 'Johnson, Dan',
			18 => 'Kendall, Jason',
			23 => 'Kielty, Bobby',
			21 => 'Kotsay, Mark',
			17 => 'Melhuse, Adam',
			16 => 'Payton, Jay',
			19 => 'Scutaro, Marco',
			33 => 'Swisher, Nick',
			12 => 'Watson, Matt',

			55 => 'Blanton, Joe',
			50 => 'Calero, Kiko',
			51 => 'Cruz, Julian',
			58 => 'Duchscherer, Justin',
			47 => 'Flores, Ron',
			46 => 'Garcia, Jairo',
			40 => 'Harden, Rich',
			24 => 'Haren, Danny',
			37 => 'Kennedy, Joe',
			73 => 'Rincon, Ricardo',
			31 => 'Saarloos, Kirk',
			20 => 'Street, Huston',
			45 => 'Witasick, Jay',
			13 => 'Yabu, Keiichi',
			75 => 'Zito, Barry',
		},
		lefties => [
			37, 47, 73, 75
		],
		lineup	=> [
			[14, 4],
			[18, 2],
			[21, 8],
			[ 3, 5],
			[16, 7],
			[10, 0],
			[11, 3],
			[26, 9],
			[19, 6],
		],
	}
});

$s->play_ball(<<'EOT');
inn T1
	ab
		p b b s b
		bb
		tout 2 DP
	ab
		p s f
		DP6-4-3
	ab
		p b s
		6-3

inn B1
	ab
		p b
		out 4-3
	ab
		p s
		G2
	ab
		p s b f b
		G3

inn T2
	ab
		p f b b s
		4-3
	ab
		p b
		5-3
	ab
		p b f f f
		F7

inn B2
	ab
		p s f
		K
	ab
		p s s
		hit 2 cl
		-> 3
		-> U PB
	ab
		p s b f
		hit 1 cl
	ab
		p b f s f
		K
		pb

	ab
		p b f s b
		K

inn T3
	ab
		p s s b b
		K
	ab
		p b s
		5-3
	ab
		p s
		6-3

inn B3
	ab
		p b s
		F7
	ab
		p b s b f b
		bb
		tout 2 DP
	ab
		DP6-4-3

inn T4
	ab
		p s
		hit 2 l GR
		-> 3
		-> U
	ab
		p s b f f
		hit 1 rc
		tout 2 FC8-6
	ab
		p f s
		reach FC
		rbi
		-> 3
		-> U
	ab
		p s b
		hit 1 r
		-> 3
	ab
		hit 1 rc
		rbi
		tout 2 DP
	ab
		p f b
		DP 4-6-4

inn B4
	ab
		p s s b f
		F8
	ab
		p b
		hit 2 cl
	ab
		p b b s s f f
		K
	ab
		p b s b s
		K

inn T5
	ab
		p b b s
		G3
	ab
		p b
		6-3
	ab
		p b b s
		hit 1 lc
	ab
		p b s
		FO2

inn B5
	ab
		p s b f f b
		4-3
	ab
		p b s
		5-3
	ab
		p s
		hit 2 r
	ab
		p s b b s b
		4-3

inn T6
	ab
		p b s b f b
		hit 1 cl
		-> 2
	ab
		p f f b
		F7
	ab
		p s s
		G3
	ab
		p s f f
		4-3

inn B6
	ab
		p s f b b
		6-3
	ab
		p b s f
		hit 4 l
	ab
		p b b f b f
		bb
		tout 2 DP
	ab
		p s
		DP6-4-3

inn T7
	ab
		p s f b b
		F5
	ab
		p b
		hit 1 lc
	ab
		p s f f
		K
	ab
		p s s
		K

inn B7
	ab
		p b f s b b
		bb
		add_player 6 39 PR
		-> 2
	ab
		p s s f b
		hit 1 il

	add_pitcher 50
	ab
		p f f b
		!K
	ab
		p s s b
		K

	add_pitcher 73
	ab
		p s b b s b
		bb
		tout 2 G6 3 58

	add_pitcher 58
	ab
		p b s
		reach FC

add_player 6 7 9 8
inn T8

	ab
		p s b
		F8
	ab
		p b s b s
		5-3
	ab
		p b
		3-1

inn B8
	ab
		p b s s
		5-3
	ab
		p s b s b
		!K
	ab
		p s f
		F9

add_player 5 19 3 9
inn T9
	ab
		4-3
	ab
		p b
		4-3
	ab
		p s s b b
		F8

inn B9
	ab
		p s s
		!K
	ab
		p s f f
		!K
	ab
		p f b s b
		!K

inn T10
	add_pitcher 50
	ab
		6-3

	add_player 8 33 PH/9
	ab
		p b b b s f
		L8
	ab
		p s
		hit 2 r
		-> 3 WP
	ab
		p s s b b b f
		wp
		6-3

inn B10
	add_pitcher 51
	ab
		p s b f f f b
		hit 2 r
		add_player 9 40 PR
		-> 3
		-> 4
	ab
		p b s
		4-3

	# Ginter subs in LF
	ha
	add_player 5 6 7
	ha

	ab
		p b b f b
		hp
		-> 2
		-> 3
	ab
		p b b b
		ibb
		-> 2

	add_pitcher 13
	ab
		p s b
		hp
		rbi

	loss 51

inn
	win 50

EOT

$s->totals;

my $pdffile = $s->generate;
print $pdffile, "\n";

$s->pdfopen;

__END__
