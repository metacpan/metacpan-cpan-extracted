#!/usr/bin/perl -w
use strict;
use vars qw($loaded);

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mail::TieFolder;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my %h;
my $folder="+/tmp/Mail::TieFolder.tmp$$";
`inc $folder -silent -file t/inbox`;

# TIEHASH
tie (%h, 'Mail::TieFolder', 'mh', $folder) && print "ok 2\n";

# EXISTS
print "ok 3\n" if exists $h{'<200011110851.AAA08177@roton.terraluna.org>'};
print "ok 4\n" unless exists $h{'<200011110851.AAA08177'};

# FETCH
my $msg = $h{'<200011110851.AAA08177@roton.terraluna.org>'};
print "ok 5\n" if $msg;
my $header = $msg->head;
my $testdate = $header->get('Date');
# print "$testdate\n";
print "ok 6\n" if $testdate eq 'Sat, 11 Nov 2000 00:51:50 -0800' . "\n";

# FIRSTKEY/NEXTKEY
print "ok 7\n" if keys %h == 2;

# print join("\n", keys %h);
# print "\n";

`rmf $folder`;
