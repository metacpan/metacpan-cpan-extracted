#!/usr/bin/perl -w
#
# simple ps(1) lookalike
#
# $Id: example2.pl,v 1.1 2003/03/31 17:42:16 deschwen Exp $

use ExtUtils::testlib;
use HPUX::Pstat;

$psd = HPUX::Pstat::getdynamic();
$pss = HPUX::Pstat::getproc($psd->{"psd_activeprocs"} + 10);

print "PID   PPID  CMD\n";
foreach $p (@$pss) {
    printf "%5d %5d %s\n", $p->{"pst_pid"}, $p->{"pst_ppid"}, $p->{"pst_cmd"};
}
