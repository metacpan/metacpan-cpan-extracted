# -*- perl -*-

use strict;
require ExtUtils::MakeMaker;

my %prereqs = (
	GD => '2.30'
);

my %opts = (
	'NAME' => 'GD::Tiler',
	'VERSION_FROM' => 'lib/GD/Tiler.pm',
	'dist'         => {
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf'
    },
	'AUTHOR'       => 'Dean Arnold, Presicient Corp. (darnold@presicient.com)',
	'ABSTRACT'     => 'simple image tiler using GD',
	'PREREQ_PM'    => \%prereqs
);

ExtUtils::MakeMaker::WriteMakefile(%opts);
