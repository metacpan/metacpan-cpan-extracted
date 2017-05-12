use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'          => 'HTML::CheckArgs',
	'VERSION_FROM'  => 'lib/HTML/CheckArgs.pm',
	'ABSTRACT_FROM' => 'lib/HTML/CheckArgs.pm',
	'PREREQ_PM'     => {
		'Carp',                => 0,
		'Email::Valid'         => 0.15,
		'Geography::Countries' => 1.4,
		'HTML::FormatData'     => 0.08,
		'LWP::UserAgent'       => 2.031,
		'Scalar::Util'         => 1.14,
		'URI::Find'            => 0.14,
	},
	AUTHOR          => 'Eric Folley <eric@folley.net>',
);
