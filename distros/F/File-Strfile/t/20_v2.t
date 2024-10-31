#!/usr/bin/perl
use 5.016;
use strict;

use Test::More tests => 35;

use File::Spec;

use File::Strfile qw(%STRFLAGS);

my $TEST_SRC = "t/data/v2.txt";
my $TEST_SRC_PATH = File::Spec->catfile(split /\//, $TEST_SRC);
my $TEST_STRFILE_PATH = "$TEST_SRC_PATH.dat";
my $TEST_OUT_PATH = "test.out";

my %IDEALITY = (
	Version  => 2,
	StrNum   => 5,
	LongLen  => 100,
	ShortLen => 54,
	Flags    => 0,
	Delimit  => '%',
	Offsets  => [
		0x0000,
		0x0052,
		0x00b8,
		0x0105,
		0x013f,
		0x0175,
	],
	Ordered => [
		0x0052,
		0x013f,
		0x0000,
		0x00b8,
		0x0105,
		0x0175,
	],
	Is     => 4,
);

# obj1 will test the creation of a strfile from scratch
my $obj1 = File::Strfile->new($TEST_SRC_PATH, { Version => 2 });
isa_ok($obj1, 'File::Strfile', "new creates File::Strfile object");

is($obj1->get('Version'),  $IDEALITY{Version},  "Version is correct");
is($obj1->get('StrNum'),   $IDEALITY{StrNum},   "String number is correct");
is($obj1->get('LongLen') , $IDEALITY{LongLen},  "Longest string length is correct");
is($obj1->get('ShortLen'), $IDEALITY{ShortLen}, "Shortest string length is correct");
is($obj1->get('Flags'),    $IDEALITY{Flags},    "Flags are correct");
is($obj1->get('Delimit'),  $IDEALITY{Delimit},  "Delimit character is correct");

is_deeply($obj1->get('Offsets'), $IDEALITY{Offsets}, "Offset list is correct");

$obj1->order();
is_deeply($obj1->get('Offsets'), $IDEALITY{Ordered}, "Ordered offset list is correct");

$obj1->order(1);
is_deeply($obj1->get('Offsets'), $IDEALITY{Ordered}, "Case-insensitive ordered offset list is correct");

# obj2 will test reading a pre-existing strfile (created from BSD strfile v2)
my $obj2 = File::Strfile->new($TEST_SRC_PATH, { DataFile => $TEST_STRFILE_PATH });
isa_ok($obj2, 'File::Strfile', "new w/ DataFile creates File::Strfile object");

is($obj2->get('Version'),  $IDEALITY{Version},  "Version read is correct");
is($obj2->get('StrNum'),   $IDEALITY{StrNum},   "String number read is correct");
is($obj2->get('LongLen'),  $IDEALITY{LongLen},  "Longest string length read is correct");
is($obj2->get('ShortLen'), $IDEALITY{ShortLen}, "Shortest string length read is correct");
is($obj2->get('Flags'),    $IDEALITY{Flags},    "Flag read is correct");
is($obj2->get('Delimit'),  $IDEALITY{Delimit},  "Delimit character read is correct");

is_deeply($obj2->get('Offsets'), $IDEALITY{Offsets}, "Offset list read is correct");

foreach my $s ($obj2->strings()) {
	ok(length $s >= $IDEALITY{ShortLen} && length $s <= $IDEALITY{LongLen},
		"Strings seem sane");
}

is(scalar $obj2->strings_like(qr/is/), $IDEALITY{Is}, "strings_like works");

$obj2->write_strfile($TEST_OUT_PATH);

# obj3 will test reading a file written by write_strfile().
my $obj3 = File::Strfile->new($TEST_SRC_PATH, { DataFile => $TEST_OUT_PATH });

is($obj3->get('Version'),  $IDEALITY{Version},  "Version written is correct");
is($obj3->get('StrNum'),   $IDEALITY{StrNum},   "String number written is correct");
is($obj3->get('LongLen'),  $IDEALITY{LongLen},  "Longest string length written is correct");
is($obj3->get('ShortLen'), $IDEALITY{ShortLen}, "Shortest string length written is correct");
is($obj3->get('Flags'),    $IDEALITY{Flags},    "Flag written is correct");
is($obj3->get('Delimit'),  $IDEALITY{Delimit},  "Delimit character written is correct");

is_deeply($obj3->get('Offsets'), $IDEALITY{Offsets}, "Offset list written is correct");

# obj4 will test overriding fields when reading a pre-existing data file
my $obj4 = File::Strfile->new($TEST_SRC_PATH, {
	DataFile => $TEST_STRFILE_PATH,
	Version  => 1,
	FcOrder  => 1,
	Rotate   => 1,
	Delimit  => 'a' # This should end up still being a %
});

is($obj4->get('Version'), 1,                 "Version override works");
is($obj4->get('Delimit'), '%',               "Delimit cannot override");
ok($obj4->get('Flags') & $STRFLAGS{ORDERED}, "Order override works");
ok($obj4->get('Flags') & $STRFLAGS{ROTATED}, "Rotate override works");

END {
	unlink $TEST_OUT_PATH if -e $TEST_OUT_PATH;
}
