#!/local/bin/perl
#
# Test printing to multiple filehandles with a single call
#
# File: multout.t
#
# Author: Nem W Schlecht
# Last Modification: $Date: 1998/08/07 22:50:58 $
#
# $Id: multi.t,v 1.1 1998/08/07 22:50:58 nem Exp nem $
# $Log: multi.t,v $
# Revision 1.1  1998/08/07 22:50:58  nem
# Initial revision
#
#
# Copyright © 1996 by Nem W Schlecht.  All rights reserved.
# This is free software; you can distribute it and/or
# modify it under the same terms as Perl itself.
#

use IO::File::Multi;
use POSIX;
use IO::File;
use strict;
print "1..4\n";

my($mh1) = new IO::File::Multi;
my($tmp1) = POSIX::tmpnam();
my($tmp2) = POSIX::tmpnam();
my($tmp3) = POSIX::tmpnam();
$mh1->open(">$tmp1");
$mh1->open(">$tmp2");
$mh1->open(">$tmp3");
$mh1->print("File 1: $tmp1\n");
$mh1->printf("File 2: %s\n", $tmp2);
$mh1->print("Just another line\n");

#
# Print to both STDOUT and file
my($mh2) = new IO::File::Multi;
my($tmp4) = POSIX::tmpnam();
$mh2->open(">-");
$mh2->open(">$tmp4");
$mh2->print("ok 1\n");
undef($mh2);

#
# Check # of lines in temp file
my($check) = new IO::File;
$check->open("$tmp4");
while (<$check>) { }
if ($. == 1) { print "ok 2\n"}
else { print "not ok 2\n" }
$check->close();


#
#
my(@allfhs) = $mh1->members();
if (scalar(@allfhs) == 3) {
    print "ok 3\n";
} else {
    print "not ok 3\n";
}
my($file3)=pop(@allfhs);
$file3->print("adding one more line\n");
undef(@allfhs);
undef($mh1);

#
# Check size of test files
my($lcfh1) = new IO::File;
my($lcfh2) = new IO::File;
my($lcfh3) = new IO::File;
$lcfh1->open("$tmp1");
$lcfh2->open("$tmp2");
$lcfh3->open("$tmp3");
while (<$lcfh1>) { }
my($lc1) = $.;
while (<$lcfh2>) { }
my($lc2) = $.;
while (<$lcfh3>) { }
my($lc3) = $.;
if (!($lc1 == $lc2 && (($lc2+1) == $lc3) && $lc1 == 3)) {
    print  "not ok 4\n";
} else {
    print "ok 4\n"
}

$lcfh1->close();
$lcfh2->close();
$lcfh3->close();

sub END {
    unlink($tmp1,$tmp2,$tmp3,$tmp4);
}
