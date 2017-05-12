#                              -*- Mode: Perl -*- 
# sfgate.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed Apr  3 10:21:38 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Wed Apr  3 10:22:42 1996
# Language        : Perl
# Update Count    : 2
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker: pfeifer $
# $Log: sfgate.t,v $
# Revision 0.1.1.2  1996/05/23 14:18:30  pfeifer
# patch11:
#
# 

BEGIN {print "1..5\n";}
END {print "not ok 1\n" unless $loaded;}
use Logfile::SFgate;
$loaded = 1;
print "ok 1\n";
$l = new Logfile::SFgate  File => 't/sfgate.log', 
                          Group => [Database,Hour,Date];
print "\nok 2\n";
$l->report(Group => Database, List => [Queries, Records], Sort => Queries);
print "\nok 3\n";
$l->report(Group => Hour, List => Records);
print "\nok 4\n";
$l->report(Group => Date, List => Records);
print "\nok 5\n";

1;
