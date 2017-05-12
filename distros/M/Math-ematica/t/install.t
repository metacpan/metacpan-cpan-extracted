#!/usr/local/bin/perl 
#                              -*- Mode: Perl -*- 
# $Basename: install.t $
# $Revision: 1.1 $
# Author          : Ulrich Pfeifer
# Created On      : Sun Jan 25 18:34:23 1998
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Apr 17 18:07:02 2005
# Language        : CPerl
# Update Count    : 69
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1998,2005 Ulrich Pfeifer, all rights reserved.
# 
#

BEGIN { $|= 1; print "1..2\n" };

open(MATH, "|math 2>&1") or die "Could not run 'math': $!\n";
print MATH qq{Install["$^X ./t/install.pl"]\n};
while (<DATA>) {
  print MATH;
}
close MATH;
__DATA__
AddTwo[2,3]
Add2[2,3]
Quit
