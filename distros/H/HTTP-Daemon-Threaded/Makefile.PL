# -*- perl -*-

require 5.008;

use strict;
require ExtUtils::MakeMaker;

eval { require 5.008; } or die << 'EOD';
#######################################
#
#	This module requires a minimum Perl version of 5.8.0
#	Please upgrade!
#
#######################################
EOD

my %prereqs = (
	'Thread::Apartment' => '0.51',
	'Module::Util' => '1.01',
	'HTTP::Daemon' => '1.36',
	'IO::Stringy' => '2.110'
);

ExtUtils::MakeMaker::WriteMakefile(
	'NAME' => 'HTTP::Daemon::Threaded',
	'VERSION_FROM' => 'lib/HTTP/Daemon/Threaded.pm',
	'dist'         => {
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf'
    },
	'AUTHOR'       => 'Dean Arnold, Presicient Corp. (darnold@presicient.com)',
	'ABSTRACT'     => 'Apartment threaded web server',
	'PREREQ_PM'    => \%prereqs,
);
