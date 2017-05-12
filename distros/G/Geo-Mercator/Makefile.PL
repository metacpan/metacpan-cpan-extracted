# -*- perl -*-

use strict;
require ExtUtils::MakeMaker;

my %opts = (
	'NAME' => 'Geo::Mercator',
	'VERSION_FROM' => 'lib/Geo/Mercator.pm',
	'dist'         => {
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf'
    },
	'AUTHOR'       => 'Dean Arnold, Presicient Corp. (darnold@presicient.com)',
	'ABSTRACT'     => 'Compute Mercator Projections',
);

ExtUtils::MakeMaker::WriteMakefile(%opts);
