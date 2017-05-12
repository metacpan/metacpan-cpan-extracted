#!/usr/bin/perl
use warnings;
use strict;

use Games::Baseball::Scorecard;

my $s = Games::Baseball::Scorecard->new;
$s->debug(1);

my %teams = (
	'Boston Red Sox' => {
		roster  => {
			12 => 'Bellhorn, Mark',
			44 => 'Cabrera, Orlando',
			18 => 'Damon, Johnny',
			19 => 'Kapler, Gabe',
			15 => 'Millar, Kevin',
			13 => 'Mientkiewicz, Doug',
			28 => 'Mirabelli, Doug',
			11 => 'Mueller, Bill',
			 7 => 'Nixon, Trot',
			34 => 'Ortiz, David',
			24 => 'Ramirez, Manny',
			 3 => 'Reese, Pokey',
			33 => 'Varitek, Jason',

			61 => 'Arroyo, Bronson',
			43 => 'Embree, Alan',
			29 => 'Foulke, Keith',
			32 => 'Lowe, Derek',
			45 => 'Martinez, Pedro',
			38 => 'Schilling, Curt',
			50 => 'Timlin, Mike',
			49 => 'Wakefield, Tim',
		},
		lefties => [
			43
		],
	},

	'St. Louis Cardinals' => {
		roster  => {
			 8 => 'Anderson, Marlon',
			32 => 'Cedeno, Roger',
			15 => 'Edmonds, Jim',
			 7 => 'Luna, Hector',
			47 => 'Mabry, John',
			22 => 'Matheny, Mike',
			41 => 'Molina, Yadier',
			 5 => 'Pujols, Albert',
			 3 => 'Renteria, Edgar',
			27 => 'Rolen, Scott',
			16 => 'Sanders, Reggie',
			99 => 'Taguchi, So',
			33 => 'Walker, Larry',
			 4 => 'Womack, Tony',

			40 => 'Calero, Kiko',
			23 => 'Eldred, Carl',
			55 => 'Haren, Danny',
			44 => 'Isringhausen, Jason',
			56 => 'King, Ray',
			21 => 'Marquis, Jason',
			35 => 'Morris, Matt',
			52 => 'Reyes, Aal',
			37 => 'Suppan, Jeff',
			50 => 'Tavarez, Julian',
			19 => 'Williams, Woody',
		},
		lefties => [
			56
		],
	}
);

$s->play_ball(join('', <>), { teams => \%teams });

$s->totals;

printf "%s\n", my $pdffile = $s->generate;

$s->pdfopen;

__END__
