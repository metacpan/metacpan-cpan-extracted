# $Id: Makefile.PL,v 1.2 2005/06/28 07:04:50 mark Exp $

require 5.005;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile (
	'NAME'         => 'HTML::Chunks',
	'VERSION_FROM' => 'lib/HTML/Chunks.pm', # gets version 
	'PREREQ_PM'    => { 
		'Test::More'  => '0',
		'IO::Scalar'  => '0', 
		'Safe'        => '0', 
	},
);
