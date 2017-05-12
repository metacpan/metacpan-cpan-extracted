#!/usr/bin/perl
use warnings;
use strict;

use File::Basename;
use File::Spec::Functions qw(:DEFAULT rel2abs);
use Games::Baseball::Scorecard;

my $s = Games::Baseball::Scorecard->new;
$s->debug(1);

my $file = $ARGV[0];
my($name, $dir) = fileparse($file, qr{\.txt});
$dir = rel2abs($dir) unless file_name_is_absolute($dir);
my $newpdf = catfile($dir, $name . '.pdf');

my %teams = (
	'Boston Red Sox' => {
		roster  => {
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
			60 => 'Ramirez, Hanley',
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
			56 => 'Hansen, Craig',
			43 => 'Harville, Chad',
			36 => 'Myers, Mike',
			58 => 'Papelbon, Jonathan',
			38 => 'Schilling, Curt',
			50 => 'Timlin, Mike',
			49 => 'Wakefield, Tim',
			16 => 'Wells, David',
		},
		lefties => [
			55, 36, 16
		],
	},

	'Chicago White Sox' => {
		roster  => {
			44 => 'Anderson, Brian',
			27 => 'Blum, Geoff',
			25 => 'Borchard, Joe',
			31 => 'Casanova, Raul',
			24 => 'Crede, Joe',
			23 => 'Dye, Jermaine',
			 8 => 'Everett, Carl',
			17 => 'Gload, Ross',
			 1 => 'Harris, Willie',
			15 => 'Iguchi, Tadahito',
			14 => 'Konerko, Paul',
			38 => 'Ozuna, Pablo',
			 7 => 'Perez, Timo',
			12 => 'Pierzynski, A.J.',
			22 => 'Podsednik, Scott',
			33 => 'Rowand, Aaron',
			 5 => 'Uribe, Juan',
			36 => 'Widger, Chris',

			57 => 'Bajenaru, Jeff',
			56 => 'Buehrle, Mark',
			52 => 'Contreras, Jose',
			46 => 'Cotts, Neal',
			34 => 'Gracia, Freddy',
			20 => 'Garland, Jon',
			32 => 'Hermanson, Dustin',
			26 => 'Hernandez, Orlando',
			45 => 'Jenks, Bobby',
			43 => 'Marte, Damaso',
			41 => 'McCarthy, Brandon',
			18 => 'Politte, Cliff',
			65 => 'Sanders, David',
			51 => 'Vizcaino, Luis',
		},
		lefties => [
			56, 46, 43, 65
		],
	}
);

$s->play_ball(join('', <>), { teams => \%teams });

$s->totals;

printf "%s\n", my $pdf = $s->generate;

$s->pdfopen;

system 'cp', $pdf, $newpdf;

__END__
