#                              -*- Mode: Perl -*- 
# info.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Fri Dec 13 13:36:55 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Thu Jan 16 16:19:55 1997
# Language        : CPerl
# Update Count    : 12
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker$
# $Log$
# 

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use InfoBrief;
$loaded = 1;
print "ok 1\n";

if (! -e 'infobrief') {
  system "make infobrief" and
    die "Could not 'make infobrief: $!";
}
system qq($^X infobrief <t/test.adr >t/test.ps);

use IO::File;
my $is     = new IO::File "<t/test.ps";
my $should = new IO::File "<t/should.ps";
my ($l,$r);
my $err = 0;
while (defined ($l = <$is>)) {
  $r = <$should>;
  chomp($r); chomp($l);
  unless ($l =~ /^%%CreationDate/) {
    $err++ unless $l eq $r;
  }
}
print ((!$err)?"ok 2\n":"not ok 2\nErrors: $err\n");

