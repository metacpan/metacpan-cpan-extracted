#!/usr/bin/perl

use ExtUtils::MakeMaker;

my $prereqs = { 'Carp' 		=> 0,
		'Archive::Zip' 	=> 0,
		'GD'		=> 0,
		'File::Temp'	=> 0,
		'Statistics::Descriptive' => 0 };
WriteMakefile(
	NAME		=> 'Geo::KML::PolyMap',
	VERSION_FROM 	=> 'lib/Geo/KML/PolyMap.pm',
	PREREQ_PM	=> $prereqs
);

