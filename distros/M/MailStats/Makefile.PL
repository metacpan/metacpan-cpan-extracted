#!/usr/bin/perl -w
use lib "lib";
use ExtUtils::MakeMaker;
use strict;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Mail::Stats',
    'VERSION_FROM' => 'lib/Mail/Stats.pm', # finds $VERSION
    'EXE_FILES' => [qw(countmail)],
    'PREREQ_PM' => { 'AppConfig' => 1 },
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other'
);
