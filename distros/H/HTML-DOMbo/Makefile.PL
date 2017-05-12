# This -*-perl-*- script writes the Makefile for installing this distribution.
#
# See "perldoc perlmodinstall" or "perldoc ExtUtils::MakeMaker" for
# info on how to control how the installation goes.
#
#                                       Time-stamp: "2005-01-04 21:08:48 AST"

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'HTML::DOMbo',
    'VERSION_FROM' => 'lib/HTML/DOMbo.pm', # finds $VERSION
    'PREREQ_PM'    => { 'XML::DOM'=> '0', },

    'dist'         => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);
