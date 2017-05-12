# This -*-perl-*- script writes the Makefile for installing this distribution.
#
# See "perldoc perlmodinstall" or "perldoc ExtUtils::MakeMaker" for
# info on how to control how the installation goes.
#
#                                       Time-stamp: "2005-01-29 15:11:45 AST"

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'MIDI-Perl',
   VERSION_FROM  => 'lib/MIDI.pm',
   ABSTRACT  => 'read, compose, modify, and write MIDI files',
   'dist'        => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);
