#                              -*- Mode: Perl -*- 
# wftp.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed Apr  3 10:22:06 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Wed Apr  3 10:22:30 1996
# Language        : Perl
# Update Count    : 2
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker: pfeifer $
# $Log: wftp.t,v $
# Revision 0.1.1.4  1996/05/23 14:18:33  pfeifer
# patch11:
#
# 

BEGIN {print "1..6\n";}
END {print "not ok 1\n" unless $loaded;}
use Logfile::Wftp;
$loaded = 1;
print "\nok 1\n";

$l = new Logfile::Wftp  File => 't/wftp.log', 
                        Group => [Host,Domain,File,Hour,Date];
print "\nok 2\n";
$l->report(Group => File, Sort => Records, Top => 10, List => [Bytes, Records]);
print "\nok 3\n";
$l->report(Group => Domain, Sort => Bytes, List => [Bytes, Records]);
print "\nok 4\n";
$l->report(Group => Hour, List => [Bytes, Records]);
print "\nok 5\n";
$l->report(Group => Date, List => [Bytes, Records]);
print "\nok 6\n";

1;
