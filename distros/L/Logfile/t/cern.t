#                              -*- Mode: Perl -*- 
# cern.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed Apr  3 10:20:38 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Thu Apr  4 15:56:52 1996
# Language        : Perl
# Update Count    : 3
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker: pfeifer $
# $Log: cern.t,v $
# Revision 0.1.1.5  1996/05/23 14:18:13  pfeifer
# patch11: Wn error log files.
#
# 

BEGIN {print "1..9\n";}
END {print "not ok 1\n" unless $loaded;}
use Logfile::Cern;
$loaded = 1;
print "ok 1\n";

$l = new Logfile::Cern  File  => 't/cern.log', 
                        Group => [Host,Domain,File,Hour,Date];
print "\nok 2\n";
$l->report(Group => File, Sort => Records, Top => 10);
print "\nok 3\n";
$l->report(Group => Domain, Sort => Bytes);
print "\nok 4\n";
$l->report(Group => Hour);
print "\nok 5\n";
$l->report(Group => Date);
print "\nok 6\n";
$l->report(Group => Domain, List => [Hour, Records]);
print "\nok 7\n";
$l->report(Group => Hour, List => [Bytes, Records], Sort => Hour, Top => 2);
print "\nok 8\n";
$l->report(Group => Hour, List => [Bytes, Records], Sort => Hour, Top => 2, Reverse => 1);
print "\nok 9\n";

1;
