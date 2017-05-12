use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'          => 'HTML::FormatData',
	'VERSION_FROM'  => 'lib/HTML/FormatData.pm',
	'ABSTRACT_FROM' => 'lib/HTML/FormatData.pm',
	'PREREQ_PM'     => {
		'Carp'                        => 0,
		'DateTime'                    => 0.22,
		'DateTime::Format::Strptime'  => 1.0601,
		'HTML::Entities'              => 1.27,
		'HTML::Parser'                => 3.35,
		'URI::Escape'                 => 3.22,
	},
	AUTHOR	        => 'Eric Folley <eric@folley.net>',
);
