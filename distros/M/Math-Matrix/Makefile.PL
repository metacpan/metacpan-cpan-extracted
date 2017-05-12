#!/usr/local/ls6/perl/bin/perl
#                              -*- Mode: Perl -*- 
# Makefile.PL -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Fri Oct 27 11:19:11 1995
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Fri May 17 10:30:41 2013
# Language        : Perl
# Update Count    : 9
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1995, Universität Dortmund, all rights reserved.
# 
# $Locker$
# $Log$
# 


use ExtUtils::MakeMaker;
use Config;

&WriteMakefile(
               'NAME'     => 'Math::Matrix',
               'LINKTYPE' => '$(INST_PM)',
               'VERSION_FROM'  => 'Matrix.pm',
               'dist'     => { SUFFIX => 'gz', COMPRESS => 'gzip -f' },
               'clean' 	  => {'FILES' => '*~'},
);
