#!/usr/bin/perl -w
use strict;
use vars qw($loaded);

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mail::TieFolder;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my %h;
my $folder="+/tmp/Mail::TieFolder.tmp$$";


use Mail::Internet;
open(MSG,"t/msg1") || die $!;
my $msg1 = new Mail::Internet \*MSG;
print "ok 2\n" if $msg1;

my $unseen;

# check unseen, unseen flag off
tie (%h, 'Mail::TieFolder', 'mh', $folder, {'unseen' => 0}) && print "ok 3\n";
# store
$h{'new'} = $msg1;
# should be seen
chomp($unseen = `pick $folder unseen 2>/dev/null`);
print "ok 4\n" unless $unseen;
# read
print "ok 5\n" if $h{'<200011112208.OAA20760@roton.terraluna.org>'};
# should be seen
chomp($unseen = `pick $folder unseen 2>/dev/null`);
print "ok 6\n" unless $unseen;
`rmf $folder`;

# check unseen, unseen flag on
tie (%h, 'Mail::TieFolder', 'mh', $folder, {'unseen' => 1}) && print "ok 7\n";
# store
$h{'new'} = $msg1;
# should be unseen
chomp($unseen = `pick $folder unseen`);
print "ok 8\n" if $unseen == 1;
# read
print "ok 9\n" if $h{'<200011112208.OAA20760@roton.terraluna.org>'};
# should be unseen
chomp($unseen = `pick $folder unseen`);
print "ok 10\n" if $unseen == 1;
`rmf $folder`;

# check unseen, no unseen flag (defaults to on)
tie (%h, 'Mail::TieFolder', 'mh', $folder) && print "ok 11\n";
# store
$h{'new'} = $msg1;
# should be unseen
chomp($unseen = `pick $folder unseen`);
print "ok 12\n" if $unseen == 1;
# read
print "ok 13\n" if $h{'<200011112208.OAA20760@roton.terraluna.org>'};
# should be unseen
chomp($unseen = `pick $folder unseen`);
print "ok 14\n" if $unseen == 1;
`rmf $folder`;

