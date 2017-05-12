
# $Id: Makefile.PL,v 1.3 1999/02/11 19:26:01 msolomon Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Geo::WeatherNOAA',
    'VERSION_FROM' => 'WeatherNOAA.pm', # finds $VERSION
     'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
                         'ZIP'=>'zip','ZIPFLAGS'=>'-rl'},
	'PREREQ_PM' => {'Tie::IxHash' => 0,
					'LWP::Simple' => 0,
					'LWP::UserAgent' => 0 }

);
