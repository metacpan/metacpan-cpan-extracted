#
# Makefile.PL
#
# Make a Makefile for Image::BioChrome
#
use strict;
use ExtUtils::MakeMaker;

eval "use File::MMagic";

if ($@ || $File::MMagic::VERSION < 1.21) {
	die(<<EOF);

Image::BioChrome requires at least version 1.21 of File::MMagic

EOF
}





WriteMakefile(
	'NAME'	=> 'Image::BioChrome',
	'VERSION_FROM' => 'lib/Image/BioChrome.pm', # finds $VERSION
	'PMLIBDIRS' => [ 'lib' ],
	dist => {
		PREOP => 'pod2text lib/Image/BioChrome.pm > README && cvs commit -m "new dist release" README',
		SUFFIX => 'gz',
		COMPRESS => 'gzip -9',
	},
	clean => {
		'FILES' => join(' ', qw( t/gif/output.gif 
								 t/gif/output2.gif
								 t/tmp/biochrome/alpha_ff0000_0000ff/simple.gif
								 t/tmp/biochrome/ff0000_0000ff/simple.jpg
								 t/gif/output3.gif )),
	},
);

