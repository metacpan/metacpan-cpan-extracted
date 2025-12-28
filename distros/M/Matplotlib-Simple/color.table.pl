#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Matplotlib::Simple;

my %bond_dissociation_energy = ( # kJ/mol
	H  => {
		H  => 436.002,
		F  => 568.6,
		Cl => 431.8,
		Br => 365.7,
		I  => 298.7
	},
	F  => {
		F  => 156.9,
		Cl => 250.54,
		Br => 233.8,
		I  => 280
	},
	Cl => {
		Cl => 242.580,
		Br => 218.84,
		I  => 213.3,
	},
	Br => {
		Br => 193.870,
		I  => 179.1,
	},
	I  => {
		I  => 152.549
	}
);
colored_table({
	'cblabel'     => 'kJ/mol',
	'col.labels'  => ['H', 'F', 'Cl', 'Br', 'I'],
	data          => \%bond_dissociation_energy,
	mirror        => 1,
	'output.file' => '/tmp/tab.svg',
	'row.labels'  => ['H', 'F', 'Cl', 'Br', 'I'],
	'show.numbers'=> 1,
	set_title     => 'Bond Dissociation Energy'
});
