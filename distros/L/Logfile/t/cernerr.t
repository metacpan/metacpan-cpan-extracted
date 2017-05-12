#                              -*- Mode: Perl -*- 
# cernerr.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed Apr  3 10:21:04 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Wed Apr  3 10:21:21 1996
# Language        : Perl
# Update Count    : 1
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker: pfeifer $
# $Log: cernerr.t,v $
# Revision 0.1.1.2  1996/05/23 14:18:22  pfeifer
# patch11:
#
# 

BEGIN {print "1..4\n";}
END {print "not ok 1\n" unless $loaded;}
use Logfile::CernErr;
$loaded = 1;
print "ok 1\n";
$l = new Logfile::CernErr  File => 't/cern.err', 
                           Group => [[File,Error], [Date, File, Error]];
print "\nok 2\n";
$l->report(Group => [File, Error]);
print "\nok 3\n";

$l->report(Group => [Date, File, Error]);
print "\nok 4\n";

1;
