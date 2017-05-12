#!/usr/bin/perl -w

use Test::More;
use Mail::Exchange::Message;
use Mail::Exchange::Message::Email;
use Mail::Exchange::PidTagIDs;
use Mail::Exchange::PidLidIDs;
use OLE::Storage_Lite;
use strict;
# use diagnostics;
use utf8;

plan tests => 101;

ok(1, "Load Module");

# Create a message, set various properties, and save it as a unicode
# and a latin-1 message (to check String8/String conversions)

my $message=Mail::Exchange::Message::Email->new();
ok($message, "create empty message");

ok($message->setSender('somebody@sender.org'),
				"set ascii string");
ok($message->setDisplayTo('Sómè Body latiñ-1'),
				"set string with latin-1 chars");
ok($message->setSubject('Test Subject'), "set subject");
ok($message->setBody('Body with «non-latin» unicode chars ∑√∞'),
				"set unicode string");
ok($message->set("Named Property", "named prop", 6, 0x1f,
	"00020386-0000-0000-c000-000000000046"), "set named property");
ok($message->set(PidTagCreationTime, 129943353273940000), "set time");
ok($message->set(PidTagAccess, 2), "set numeric");
ok($message->set(PidTagRtfInSync, 0), "set boolean");
ok($message->set(PidTagChangeKey, "\xde\xad\xbe\xef"), "set binary");
ok($message->set(PidLidCurrentVersionName, "12.0"), "set LID String");
ok($message->set(PidLidValidFlagStringProof, 129943352997900000),
						"set LID time");
ok($message->set(PidLidCurrentVersion, 126539), "set LID numeric");
ok($message->set(PidLidTaskComplete, 0), "set LID boolean");

ok($message->setUnicode(1), "set Unicode flag");
unlink("t/created-unicode.msg");
ok(!(-e("t/created-unicode.msg")), "no unicode message");
ok($message->save("t/created-unicode.msg"), "save unicode message");
ok(-e("t/created-unicode.msg"), "unicode message file present");

ok($message->setUnicode(0), "clear Unicode flag");
unlink("t/created-latin1.msg");
ok(!(-e("t/created-latin1.msg")), "no latin-1 message");
ok($message->save("t/created-latin1.msg"), "save latin-1 message");
ok(-e("t/created-latin1.msg"), "latin-1 message file present");


# Done creating msg files, now use Ole::Storage_Lite to verify their content

my ($OLEFile, $root);
my @expectedname=qw(
	__nameid_version1.0
	__substg1.0_001A001F __substg1.0_0037001F __substg1.0_003D001F
	__substg1.0_0042001F __substg1.0_0064001F __substg1.0_0065001F
	__substg1.0_0070001F __substg1.0_0C1A001F __substg1.0_0C1E001F
	__substg1.0_0C1F001F __substg1.0_0E02001F __substg1.0_0E03001F
	__substg1.0_0E04001F __substg1.0_0E1D001F __substg1.0_1000001F
	__substg1.0_10F3001F __substg1.0_5D01001F __substg1.0_65E20102
	__substg1.0_8000001F __substg1.0_8001001F
	__properties_version1.0
);

$OLEFile=OLE::Storage_Lite->new("t/created-unicode.msg");
$root=$OLEFile->getPpsTree(1);
isa_ok($root, "OLE::Storage_Lite::PPS::Root", "Loaded utf-8 OLE File");
SKIP: {
	skip "Can't load unicode file", 10 unless
				ref $root eq "OLE::Storage_Lite::PPS::Root";

	# We do rely on the order of the various substreams.
	# The __substg1 streams actually have to be in this order, 
	# or outlook won't be able to read the file,
	# although this isn't documented anywhere.
	for (my $i=0; $i<=$#{$root->{Child}}; $i++) {
		is(Encode::decode("UCS2LE", $root->{Child}[$i]{Name}),
			$expectedname[$i], "stream name $expectedname[$i]");
	}

	# ---- property id to property name mapping streams

	my $child;
	$child=$root->{Child}[0];
	my $guidstream=$child->{Child}[0];
	is(Encode::decode("UCS2LE", $guidstream->{Name}),
		"__substg1.0_00020102", "guidstream present");
	is(hexconv($guidstream->{Data}),
		"86 03 02 00 00 00 00 00 c0 00 00 00 00 00 00 46 ".
		"08 20 06 00 00 00 00 00 c0 00 00 00 00 00 00 46 ".
		"03 20 06 00 00 00 00 00 c0 00 00 00 00 00 00 46 ",
		"guidstream content");

	my $entrystream=$child->{Child}[1];
	is(Encode::decode("UCS2LE", $entrystream->{Name}),
		"__substg1.0_00030102", "entrystream present");
	is(hexconv($entrystream->{Data}),
		"00 00 00 00 07 00 00 00 54 85 00 00 08 00 01 00 ".
		"bf 85 00 00 08 00 02 00 52 85 00 00 08 00 03 00 ".
		"1c 81 00 00 0a 00 04 00 ",
		"entrystream content");

	my $stringstream=$child->{Child}[2];
	is(Encode::decode("UCS2LE", $stringstream->{Name}),
		"__substg1.0_00040102", "stringstream present");
	is(hexconv($stringstream->{Data}),
			"1c 00 00 00 4e 00 61 00 6d 00 65 00 64 00 20 00 ".
			"50 00 72 00 6f 00 70 00 65 00 72 00 74 00 79 00 ",
		"stringstream content");

	# ---- property name to property id mapping stream

	my $nametoidstream=$child->{Child}[6];
	is(Encode::decode("UCS2LE", $nametoidstream->{Name}),
		"__substg1.0_100E0102", "nametoidstream present");
	is(hexconv($nametoidstream->{Data}),
			"56 c8 3b b5 07 00 00 00 ", "nametoidstream content");


	# ---- property streams - we check against the hex strings instead
	# of encoding to detect any Encode errors
	# subject - plain ascii
	is(Encode::decode("UCS2LE", $root->{Child}[2]{Name}),
		"__substg1.0_0037001F",	"Subject stream name");
	is(hexconv($root->{Child}[2]{Data}),
		"54 00 65 00 73 00 74 00 20 00 53 00 ".
		"75 00 62 00 6a 00 65 00 63 00 74 00 ",
		"Subject String");

	# sendername - plain ascii
	is(Encode::decode("UCS2LE", $root->{Child}[8]{Name}),
		"__substg1.0_0C1A001F",	"Sender stream name");
	is(hexconv($root->{Child}[8]{Data}),
		"73 00 6f 00 6d 00 65 00 62 00 6f 00 64 00 ".
		"79 00 40 00 73 00 65 00 6e 00 64 00 65 00 ".
		"72 00 2e 00 6f 00 72 00 67 00 ",
		"Sender String");

	# display to - latin-1 characters
	is(Encode::decode("UCS2LE", $root->{Child}[13]{Name}),
		"__substg1.0_0E04001F",	"Displayto stream name");
	is(hexconv($root->{Child}[13]{Data}),
		"53 00 f3 00 6d 00 e8 00 20 00 42 00 6f 00 ".
		"64 00 79 00 20 00 6c 00 61 00 74 00 69 00 ".
		"f1 00 2d 00 31 00 ",
		"Displayto String");

	# body - unicode characters
	is(Encode::decode("UCS2LE", $root->{Child}[15]{Name}),
		"__substg1.0_1000001F",	"Body stream name");
	is(hexconv($root->{Child}[15]{Data}),
		"42 00 6f 00 64 00 79 00 20 00 77 00 69 00 74 00 ".
		"68 00 20 00 ab 00 6e 00 6f 00 6e 00 2d 00 6c 00 ".
		"61 00 74 00 69 00 6e 00 bb 00 20 00 75 00 6e 00 ".
		"69 00 63 00 6f 00 64 00 65 00 20 00 63 00 68 00 ".
		"61 00 72 00 73 00 20 00 11 22 1a 22 1e 22 ",
		"Body String");

	# change key - binary stuff
	is(Encode::decode("UCS2LE", $root->{Child}[18]{Name}),
		"__substg1.0_65E20102",	"Change key stream name");
	is(hexconv($root->{Child}[18]{Data}),
		"de ad be ef ",
		"Change key String");

	# named property -> id 8000
	is(Encode::decode("UCS2LE", $root->{Child}[19]{Name}),
		"__substg1.0_8000001F",	"Named Property stream name");
	is(hexconv($root->{Child}[19]{Data}),
		"6e 00 61 00 6d 00 65 00 64 00 20 00 70 00 72 00 6f 00 70 00 ",
		"Named Property String");
}

# Check the latin-1 file .. don't repeat all the property name/ID checks,
# but verify the strings, and check that we use type 001E instead of 001F now.

@expectedname=qw(
	__nameid_version1.0
	__substg1.0_001A001E __substg1.0_0037001E __substg1.0_003D001E
	__substg1.0_0042001E __substg1.0_0064001E __substg1.0_0065001E
	__substg1.0_0070001E __substg1.0_0C1A001E __substg1.0_0C1E001E
	__substg1.0_0C1F001E __substg1.0_0E02001E __substg1.0_0E03001E
	__substg1.0_0E04001E __substg1.0_0E1D001E __substg1.0_1000001E
	__substg1.0_10F3001E __substg1.0_5D01001E __substg1.0_65E20102
	__substg1.0_8000001E __substg1.0_8001001E
	__properties_version1.0
);

$OLEFile=OLE::Storage_Lite->new("t/created-latin1.msg");
$root=$OLEFile->getPpsTree(1);
isa_ok($root, "OLE::Storage_Lite::PPS::Root", "Loaded latin-1 OLE File");
SKIP: {
	skip "Can't load latin-1 file", 10 unless
				ref $root eq "OLE::Storage_Lite::PPS::Root";

	for (my $i=0; $i<=$#{$root->{Child}}; $i++) {
		is(Encode::decode("UCS2LE", $root->{Child}[$i]{Name}),
			$expectedname[$i], "stream name $expectedname[$i]");
	}

	# ---- property id to property name mapping streams

	my $child;
	$child=$root->{Child}[0];

	# ---- property streams - we check against the hex strings instead
	# of encoding to detect any Encode errors
	# subject - plain ascii
	is(Encode::decode("UCS2LE", $root->{Child}[2]{Name}),
		"__substg1.0_0037001E",	"Subject stream name");
	is($root->{Child}[2]{Data},
		"Test Subject", "Subject String");

	# sendername - plain ascii
	is(Encode::decode("UCS2LE", $root->{Child}[8]{Name}),
		"__substg1.0_0C1A001E",	"Sender stream name");
	is($root->{Child}[8]{Data},
		"somebody\@sender.org",
		"Sender String");

	# display to - latin-1 characters
	is(Encode::decode("UCS2LE", $root->{Child}[13]{Name}),
		"__substg1.0_0E04001E",	"Displayto stream name");
	is($root->{Child}[13]{Data},
		"Sómè Body latiñ-1",
		"Displayto String");

	# body - unicode characters
	is(Encode::decode("UCS2LE", $root->{Child}[15]{Name}),
		"__substg1.0_1000001E",	"Body stream name");
	is($root->{Child}[15]{Data},
		"Body with «non-latin» unicode chars ???",
		"Body String");

	# change key - binary stuff
	is(Encode::decode("UCS2LE", $root->{Child}[18]{Name}),
		"__substg1.0_65E20102",	"Change key stream name");
	is($root->{Child}[18]{Data},
		"\xde\xad\xbe\xef",
		"Change key String");

	# named property -> id 8000
	is(Encode::decode("UCS2LE", $root->{Child}[19]{Name}),
		"__substg1.0_8000001E",	"Named Property stream name");
	is($root->{Child}[19]{Data},
		"named prop",
		"Named Property String");
}

unlink("t/created-unicode.msg");
unlink("t/created-latin1.msg");

sub hexconv {
	use bytes;
	my $s=shift;
	my $r="";
	for (my $i=0; $i<length $s; $i++) {
		$r.=sprintf("%02x ", ord(substr($s, $i, 1))&0xff);
	}
	return $r;
}
