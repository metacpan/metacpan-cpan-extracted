#!/usr/local/bin/perl
#                              -*- Mode: Perl -*- 
# Makefile.PL -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Fabrizio Pivari
# Created On      : Wed Feb 25 11:37:29 1998
# 


use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
	       AUTHOR       => 'Fabrizio Pivari (fabrizio@pivari.com)',
               NAME         => 'Math::MagicSquare',
               PREREQ_PM    => {'GD'	=> '0'},
               LINKTYPE     => '$(INST_PM)',
               VERSION_FROM => 'MagicSquare.pm',
               dist         => { SUFFIX => 'gz', COMPRESS => 'gzip -f' },
               clean 	    => {'FILES' => '*~'},
);
