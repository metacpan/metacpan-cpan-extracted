#!perl
#                              -*- Mode: Perl -*- 
# Makefile.PL -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Tue Mar 26 16:20:48 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Tue Apr 29 09:05:53 2003
# Language        : Perl
# Update Count    : 34
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker: pfeifer $
# $Log: Makefile.PL,v $
# Revision 0.1.1.7  1997/01/20 09:05:27  pfeifer
# patch15: Changed code for determining if a Date parser is available.
#
# Revision 0.1.1.6  1996/04/02 08:26:56  pfeifer
# patch9: Fixed typos.
#
# Revision 0.1.1.5  1996/03/27 14:41:55  pfeifer
# patch6: Renamed Tools::Logfile to Logfile.
#
# Revision 0.1.1.4  1996/03/27 11:10:11  pfeifer
# patch5: Added support fro Tom Christiansen's GetDate.
#
# 

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# we do not use Date::GetDate since it dumps core with perl 5.002 (!?)
eval "use GetDate;";
if ($@ eq "") {
  print "You have GetDate by Tom Christiansen.\n";
  print "Good!\n";
} else {
  eval "use Date::GetDate;";
  if ($@ eq "") {
    print "You have Date::GetDate by Tom Christiansen.\n";
    print "Good!\n";
  } else {
    eval "use Time::ParseDate; use Time::JulianDay;";
    if ($@ eq "") {
      print "You have the Time-modules by David Muir Sharnoff\n";
      print "Good!\n";
    } else {
      print "You dont' have the Time-modules by David Muir Sharnoff\n";
      print "Consider installing it!\n";
      print "I will use my crude version though\n";
    }    
  }
}

WriteMakefile
  (
   'NAME'	=> 'Logfile',
   'VERSION'    => '0.302',
   'dist'       => {
                    COMPRESS => 'gzip -9f',
                    PREOP    => 'pod2text Logfile.pod > README',
                   },
  );
