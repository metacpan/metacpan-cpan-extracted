# This -*-perl-*- script writes the Makefile for installing this distribution.
#
# See "perldoc perlmodinstall" or "perldoc ExtUtils::MakeMaker" for
# info on how to control how the installation goes.
#
#                                       Time-stamp: "2004-12-29 20:20:41 AST"

require 5.005; # we need m/...\z/
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'File::Findgrep',
    'VERSION_FROM' => 'lib/File/Findgrep.pm', # finds $VERSION
    'PREREQ_PM'    => {	
	                 'Locale::Maketext' => 1.01,
	              },
    'dist'         => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);
