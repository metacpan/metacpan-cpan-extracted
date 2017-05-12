#!/usr/bin/perl -w
use strict;
use vars qw($loaded);

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mail::TieFolder;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my %h;
my $folder="+/tmp/Mail::TieFolder.tmp$$";
`inc $folder -silent -file t/inbox`;

# TIEHASH
tie (%h, 'Mail::TieFolder', 'mh', $folder) && print "ok 2\n";

use Mail::Internet;
open(MSG,"t/msg1") || die $!;
my $msg1 = new Mail::Internet \*MSG;
print "ok 3\n" if $msg1;

# STORE - incorrectly
$h{'foo'} = $msg1;
print "ok 4\n" unless $h{'<200011112208.OAA20760@roton.terraluna.org>'};

# STORE - new
$h{'new'} = $msg1;
print "ok 5\n" if $h{'<200011112208.OAA20760@roton.terraluna.org>'};

# STORE - replace incorrectly
print "ok 6\n" unless $h{'foo'} = $msg1;
print "ok 7\n" if $h{'<200011112208.OAA20760@roton.terraluna.org>'};

# STORE - replace correctly
print "ok 8\n" if $h{'<200011112208.OAA20760@roton.terraluna.org>'} = $msg1;
print "ok 9\n" if $h{'<200011112208.OAA20760@roton.terraluna.org>'};

# DELETE
print "ok 10\n" if delete $h{'<200011112208.OAA20760@roton.terraluna.org>'};
print "ok 11\n" unless $h{'<200011112208.OAA20760@roton.terraluna.org>'};
print "ok 12\n" unless exists $h{'<200011112208.OAA20760@roton.terraluna.org>'};

# STORE again
$h{'new'} = $msg1;
print "ok 13\n" if $h{'<200011112208.OAA20760@roton.terraluna.org>'};

# STORE something else
use Mail::Internet;
open(MSG,"t/msg2") || die $!;
my $msg2 = new Mail::Internet \*MSG;
print "ok 14\n" if $msg2;

$h{'<200011120345.TAA27386@roton.terraluna.org>'} = $msg2;
print "ok 15\n" if $h{'<200011120345.TAA27386@roton.terraluna.org>'};
`rmf $folder`;

# STORE - new folder
$h{'new'} = $msg1;
print "ok 16\n" if $h{'<200011112208.OAA20760@roton.terraluna.org>'};

`rmf $folder`;

