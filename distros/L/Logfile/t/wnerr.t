#                              -*- Mode: Perl -*- 
# cernerr.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed Apr  3 10:21:04 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Thu May 23 15:34:59 1996
# Language        : Perl
# Update Count    : 5
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker: pfeifer $
# $Log: wnerr.t,v $
# Revision 0.1.1.1  1996/05/23 14:19:39  pfeifer
# patch11: Test Wn error logfiles
#
# 

BEGIN {print "1..5\n";}
END {print "not ok 1\n" unless $loaded;}
use Logfile::WnErr;
$loaded = 1;
print "ok 1\n";
$l = new Logfile::WnErr  File => 't/wn.err', 
                         Group => [[File,Error], [File, Referer], [Date, File, Error]];
print "\nok 2\n";
$l->report(Group => [File, Error]);
print "\nok 3\n";

$l->report(Group => [Date, File, Error]);
print "\nok 4\n";

$l->report(Group => [File, Referer]);
print "\nok 5\n";
1;
