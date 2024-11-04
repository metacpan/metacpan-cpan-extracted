#!/usr/bin/perl
use 5.016;
use strict;

use Test::More tests => 1;

use File::Spec;

use File::Strfile qw(%STRFLAGS);

my $TEST_SRC = "t/data/nonalpha.txt";
my $TEST_SRC_PATH = File::Spec->catfile(split /\//, $TEST_SRC);

my %IDEALITY = (
	Version  => 1,
	StrNum   => 5,
	LongLen  => 169,
	ShortLen => 11,
	Flags    => $STRFLAGS{ORDERED},
	Delimit  => '%',
	Offsets  => [
		0x00c6,
		0x0000,
		0x000d,
		0x00d4,
		0x00b8,
		0x00e1,
	],
);

# Tests ordering strings that do not start with alphanumeric characters.
my $obj1 = File::Strfile->new($TEST_SRC_PATH);
$obj1->order();

is_deeply($obj1->get('Offsets'), $IDEALITY{Offsets}, "Non-alphanumeric sorting is correct");
