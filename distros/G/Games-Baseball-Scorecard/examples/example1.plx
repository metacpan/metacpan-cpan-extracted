#!/usr/bin/perl
use warnings;
use strict;

use Games::Baseball::Scorecard;

# This is a game the Sox lost, but I just scored it, so I used it.  sigh.

# http://mlb.mlb.com/NASApp/mlb/news/boxscore.jsp?gid=2005_09_09_bosmlb_nyamlb_1
# http://sports.espn.go.com/mlb/boxscore?gameId=250909110

my $s = Games::Baseball::Scorecard->new;
#$s->debug(2);

$s->init({
	scorer	=> 'Pudge',
	date	=> '2005-09-09, 19:05-22:45',
	at	=> 'Yankee Stadium, New York',
	att	=> '55,024',
	temp	=> '77 clear',
	away	=> {
		team	=> 'Boston Red Sox',
		starter	=> 16,
		roster	=> {
			23 => 'Cora, Alex',
			18 => 'Damon, Johnny',
			10 => 'Graffanino, Tony',
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
			57 => 'Declarmen, Manny',
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
			[ 7, 9],
			[33, 2],
			[15, 3],
			[11, 5],
			[10, 4],
		],
	},
	home	=> {
		team	=> 'New York Yankees',
		starter	=> 31,
		roster	=> {
			26 => 'Bellhorn, Mark',
			22 => 'Cano, Robinson',
			18 => 'Crosby, Bubba',
			25 => 'Giambi, Jason',
			 2 => 'Jeter, Derek',
			50 => 'Lawton, Matt',
			55 => 'Matsui, Hideki',
			14 => 'Phillips, Andy',
			20 => 'Posada, Jorge',
			13 => 'Rodriguez, Alex',
			28 => 'Sierra, Ruben',
			51 => 'Williams, Bernie',

			46 => 'Embree, Alan',
			36 => 'Gordon, Tom',
			42 => 'Rivera, Mariano',
			31 => 'Small, Aaron',
			56 => 'Sturtze, Tanyon',
		},
		lefties => [
			19, 41, 46, 48
		],
		lineup	=> [
			[ 2, 6],
			[51, 8],
			[13, 5],
			[25, 3],
			[55, 7],
			[28, 0],
			[20, 2],
			[22, 4],
			[50, 9],
		],
	}
});

# top inning 1
$s->inn;

	$s->ab;
		$s->pitches(qw(b));
		$s->hit(1, 'rc');
		$s->advance(2);

	$s->ab;
		$s->pitches(qw(f s));
		$s->out('K');

	$s->ab;
		$s->pitches(qw(b s b s f));
		$s->out('K');

	$s->ab;
		$s->pitches(qw(f b f f));
		$s->hit(1, 'il');

	$s->ab;
		$s->pitches(qw(b s f));
		$s->out('F6');


# bottom inning 1
$s->inn;

	$s->ab;
		$s->pitches(qw(s b b s));
		$s->out('6-3');

	$s->ab;
		$s->pitches(qw(s b));
		$s->out('5-3');

	$s->ab;
		$s->pitches(qw(b s s f));
		$s->hit(2, 'r');
		$s->advance(3);
		$s->advance('U', 'E4');

	$s->ab;
		$s->pitches(qw(s b b b s f f));
		$s->hit(1, 'rc');
		$s->error(4);
		$s->advance(2, 'E4');

	$s->ab;
		$s->pitches(qw(b b s b));
		$s->reach('bb');
		$s->tout(2, 'FC6-4');

	$s->ab;
		$s->reach('FC');

# top inning 2
$s->inn;

#XXX
#	$s->add_player(1, 40, 8);
	$s->ab;
		$s->pitches(qw(s b s f));
		$s->hit(1, 'il');
		$s->advance(2);
		$s->advance(3);
		$s->advance(4);

	$s->ab;
		$s->pitches(qw(b b));
		$s->out('F2');

	$s->ab;
		$s->pitches(qw(s s f));
		$s->hit(1, 'rc');
		$s->advance(2);
		$s->advance(4);

	$s->ab;
		$s->hit(1, 'lc');
		$s->advance(4);

	$s->ab;
		$s->pitches(qw(b));
		$s->out('SF8');
		$s->rbi;

	$s->ab;
		$s->hit(2, 'rc');
		$s->rbi(2);

	$s->ab;
		$s->pitches(qw(s b s b));
		$s->out('6-3');


# bottom inning 2
$s->inn;

	$s->ab;
		$s->pitches(qw(s s));
		$s->hit(4, 'cl');

	$s->ab;
		$s->pitches(qw(b s));
		$s->out('G3');

	$s->ab;
		$s->pitches(qw(s b));
		$s->out('4-3');

	$s->ab;
		$s->out('5-3');


# top inning 3
$s->inn;

	$s->ab;
		$s->pitches(qw(b));
		$s->out('6-3');

	$s->ab;
		$s->pitches(qw(b s s b f b));
		$s->out('K');

	$s->ab;
		$s->pitches(qw(s b b s f f b));
		$s->reach('bb');
		$s->tout(4, '7-6-2');

	$s->ab;
		$s->pitches(qw(s s));
		$s->hit(2, 'l');


# bottom inning 3
$s->inn;

	$s->ab;
		$s->pitches(qw(s s f));
		$s->out('K2-3');

	$s->ab;
		$s->pitches(qw(s s b b b f));
		$s->hit(4, 'lc');

	$s->ab;
		$s->pitches(qw(b));
		$s->hit(1, 'lc');
		$s->tout(2, 'FC6-4', 3);

	$s->ab;
		$s->out('F3');

	$s->ab;
		$s->pitches(qw(s b));
		$s->reach('FC');


# top inning 4
$s->inn;

#XXX
#	$s->add_player(1, 44, 8);
	$s->ab;
		$s->out('F7');

	$s->ab;
		$s->pitches(qw(s b));
		$s->out('6-3');

	$s->ab;
		$s->pitches(qw(s));
		$s->out('F6');


# bottom inning 4
$s->inn;

	$s->ab;
		$s->hit(1, 'lc');
		$s->advance(2);
		$s->advance(4);

	$s->ab;
		$s->out('SAC1-3');

	$s->ab;
		$s->pitches(qw(s b));
		$s->out('L6');

	$s->ab;
		$s->pitches(qw(s));
		$s->hit(1, 'cl');
		$s->rbi;

	$s->ab;
		$s->pitches(qw(b s b s b f f f));
		$s->out('4-3');


# top inning 5
$s->inn;

#XXX
#	$s->add_player(1, 19, 8);
	$s->ab;
		$s->pitches(qw(s));
		$s->out('F6');

	$s->ab;
		$s->pitches(qw(s));
		$s->out('F4');

	$s->ab;
		$s->pitches(qw(b b));
		$s->out('L6');


# bottom inning 5
$s->inn;

	$s->ab;
		$s->pitches(qw(b s b s f f f));
		$s->out('!K');

	$s->ab;
		$s->pitches(qw(b s s b b));
		$s->out('F7');

	$s->ab;
		$s->pitches(qw(b));
		$s->out('F7');


# top inning 6
$s->inn;

	$s->ab;
		$s->out('G3');

	$s->ab;
		$s->pitches(qw(s b));
		$s->out('F8');

	$s->ab;
		$s->pitches(qw(s));
		$s->reach('hp');
		$s->advance(2);

	$s->ab;
		$s->pitches(qw(b s));
		$s->hit(1, 'lc');

	$s->ab;
		$s->pitches(qw(b s s));
		$s->out('F7');


# bottom inning 6
$s->inn;

	$s->ab;
		$s->pitches(qw(b b s));
		$s->out('F7');

	$s->ab;
		$s->pitches(qw(s s b b f));
		$s->hit(1, 'ir');
		$s->advance(2);
		$s->advance(3, 'E8');
		$s->advance(4);

	$s->ab;
		$s->pitches(qw(s s));
		$s->hit(1, 'cl');
		$s->error(8);
		$s->error(6);
		$s->advance(2, 'E8');
		$s->advance(3, 'E6');
		$s->advance(4);

	$s->ab;
		$s->pitches(qw(b s s));
		$s->out('G3');

	$s->add_pitcher(53);
	$s->ab;
		$s->pitches(qw(s b b s b f f f f));
		$s->reach('bb');
		$s->advance(3);
		$s->advance(4);

	$s->ab;
		$s->pitches(qw(b s s));
		$s->hit(1, 'cr');
		$s->rbi;
		$s->advance(2);
		$s->advance(4);

	$s->ab;
		$s->pitches(qw(b b s));
		$s->hit(1, 'cl');
		$s->rbi;
		$s->advance(3);

	$s->add_pitcher(36);
	$s->ab;
		$s->pitches(qw(s b));
		$s->hit(1, 'lc');
		$s->rbi;

	$s->ab;
		$s->pitches(qw(b));
		$s->out('F9');


# top inning 7
$s->inn;

	$s->ab;
		$s->pitches(qw(s));
		$s->hit(1, 'rc');
		$s->tout(2, 'FC6-4');

	$s->ab;
		$s->pitches(qw(s b b));
		$s->reach('FC');
		$s->advance(2);
		$s->advance(3);
		$s->advance(4);

	$s->ab;
		$s->pitches(qw(s b s f b b));
		$s->reach('bb');
		$s->advance(2);
		$s->advance(3);

	$s->add_pitcher(56);
	$s->ab;
		$s->pitches(qw(s s f f f f));
		$s->reach('hp');
		$s->advance(2);

	$s->add_pitcher(46);
	$s->ab;
		$s->pitches(qw(s s b b));
		$s->error(4);
		$s->reach('E4');
		$s->rbi;
		$s->tout(2, 'DP', 0, 36);

	$s->add_pitcher(36);
	$s->ab;
		$s->pitches(qw(b s s f));
		$s->out('DP4-6-3');


# bottom inning 7
$s->inn;

	$s->add_pitcher(43);
	$s->ab;
		$s->pitches(qw(s s b f f));
		$s->out('K');

	$s->ab;
		$s->pitches(qw(b s b s b f));
		$s->out('!K');

	$s->ab;
		$s->pitches(qw(b));
		$s->hit(1, 'lc');

	$s->ab;
		$s->pitches(qw(b s b s b));
		$s->out('6-3');


# top inning 8
$s->inn;

	$s->ab;
		$s->pitches(qw(b b s s f));
		$s->out('F7');

	$s->ab;
		$s->pitches(qw(b b b s));
		$s->hit(2, 'l');

	$s->ab;
		$s->pitches(qw(b s b b s));
		$s->out('K');

	$s->ab;
		$s->pitches(qw(s s b));
		$s->out('K');


# bottom inning 8
$s->inn;

	$s->add_pitcher(54);
	$s->ab;
		$s->pitches(qw(b s s));
		$s->out('F9');

#XXX
#	$s->add_pitcher(38);
	$s->ab;
		$s->pitches(qw(b s s f));
		$s->hit(1, 'rc');

	$s->add_player(2, 18, 'PR/8', '8/9');
		$s->atbase('PR');
		$s->advance(2, 'SB');
		$s->advance(3, 'E2');
		$s->error(2);

	$s->ab;
		$s->pitches(qw(b s b b s));
		$s->out('FO2');

	$s->ab;
		$s->pitches(qw(b b s s b f f));
		$s->out('4-3');


	$s->add_player(4, 14, 3, 9);

# top inning 9
$s->inn;

	$s->add_pitcher(42);
	$s->ab;
		$s->pitches(qw(b s b));
		$s->hit(1, 'lc');
		$s->tout(2, 'FC6-4', 2);

	$s->ab;
		$s->out('F7');

	$s->ab;
		$s->pitches(qw(b s b s f));
		$s->reach('FC');

	$s->ab;
		$s->pitches(qw(b s b b s));
		$s->out('K');
		$s->atbase('rivera--', 2, 1);

	$s->win(31);

# bottom inning 9
$s->inn;

	$s->loss(16);


$s->totals;

my $pdffile = $s->generate;
print $pdffile, "\n";

$s->pdfopen;

__END__
