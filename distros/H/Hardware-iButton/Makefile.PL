#! /usr/local/bin/perl -w
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Hardware::iButton',
    'VERSION' => '0.03',
    'dist' => { COMPRESS => "gzip", SUFFIX => "gz" },
);
