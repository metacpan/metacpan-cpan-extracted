#!/usr/bin/perl
use 5.016;
use strict;

use Test::More tests => 7;

use File::Spec;

use File::Strfile qw(%STRFLAGS);

my $TEST_SRC = "t/data/flags.txt";
my $TEST_SRC_PATH = File::Spec->catfile(split /\//, $TEST_SRC);
my $TEST_STRFILE_PATH = "$TEST_SRC_PATH.dat";

my %IDEALITY = (
	Version  => 1,
	StrNum   => 4,
	LongLen  => 107,
	ShortLen => 52,
	Flags    => $STRFLAGS{ORDERED} | $STRFLAGS{ROTATED},
	Delimit  => '%',
	Offsets  => [
		0x0036,
		0x00a3,
		0x0000,
		0x00f0,
		0x0149,
	],
);

# Tests reading a file generated via `strfile -rox`
my $obj1 = File::Strfile->new($TEST_SRC_PATH, { DataFile => $TEST_STRFILE_PATH });

is($obj1->get('Version'),  $IDEALITY{Version},  "Version read is correct");
is($obj1->get('StrNum'),   $IDEALITY{StrNum},   "String number read is correct");
is($obj1->get('LongLen'),  $IDEALITY{LongLen},  "Longest string length read is correct");
is($obj1->get('ShortLen'), $IDEALITY{ShortLen}, "Shorest string length read is correct");
is($obj1->get('Flags'),    $IDEALITY{Flags},    "Flags read is correct");
is($obj1->get('Delimit'),  $IDEALITY{Delimit},  "Delimit read is correct");

is_deeply($obj1->get('Offsets'), $IDEALITY{Offsets}, "Offset list read is correct");
