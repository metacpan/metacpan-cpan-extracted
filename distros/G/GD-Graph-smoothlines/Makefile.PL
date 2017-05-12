#!/usr/bin/perl

use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile
(
	NAME    => 'GD::Graph::smoothlines',
	VERSION => 1.6,
	
	PREREQ_PM   => {
		'GD'        => '2.35',
		'GD::Graph' => '1.44',
	},
	
	## Add these new keywords supported since 5.005
	($] >= 5.005 ?
		(
		'ABSTRACT' => 'Produces smooth line charts with GD',
		'AUTHOR'   => 'Andrei Kozovsk',
		):()
	),
);
