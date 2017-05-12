#!/app/unido-i06/magic/perl
#                              -*- Mode: Perl -*- 
# Makefile.PL<2> -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Fri Dec 13 13:32:32 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Thu Jan 16 16:28:22 1997
# Language        : CPerl
# Update Count    : 5
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker$
# $Log$
# 

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
  (
   'NAME'	    => 'InfoBrief',
   'VERSION_FROM'   => 'InfoBrief.pm', # finds $VERSION
   'clean'          => {'FILES' => '*~ *.bak *.old infobrief t/*~ t/test.ps'},
   'dist'           => { SUFFIX => 'gz', COMPRESS => 'gzip -f' },
   'PL_FILES'       => {'infobrief.PL' => 'infobrief'},
   'EXE_FILES'      => [qw(infobrief)],
  );
