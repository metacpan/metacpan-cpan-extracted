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

my %opts = (
	NAME => 'HTML::ListToTree',
	VERSION_FROM => 'lib/HTML/ListToTree.pm',
	dist       => {
	 	DIST_DEFAULT => 'all tardist',
     	SUFFIX       => 'gz',
	 	COMPRESS     => 'gzip -9vf'
    },
    PREREQ_PM => { 'HTML::TreeBuilder', '0.0' },
	AUTHOR       => 'Dean Arnold, Presicient Corp. (darnold@presicient.com)',
	ABSTRACT     => 'Generate Javscript tree from HTML nested lists',
);

ExtUtils::MakeMaker::WriteMakefile(%opts);

