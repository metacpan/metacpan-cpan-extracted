use strict;
use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test::More 'no_plan';
use File::Slurp;

use_ok 'Locale::PO';

my $po = new Locale::PO(
    -msgid  => 'This is not a pipe',
    -msgstr => "",
    -comment =>
        "The entry below is\ndesigned to test the ability of the comment fill code to properly wrap long comments as also to properly normalize the po entries. Apologies to Magritte.",
    -fuzzy => 1
);
ok $po, "got a po object";

my $out = $po->dump;
ok $out, "dumped the po object";

my @po = $po;
$po = new Locale::PO(
    -msgid  => '',
    -msgstr => <<'EOT'
Project-Id-Version: PACKAGE VERSION
PO-Revision-Date: YEAR-MO-DA HO:MI +ZONE
Last-Translator: FULL NAME <EMAIL@ADDRESS>
Language-Team: LANGUAGE <LL@li.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=CHARSET
Content-Transfer-Encoding: ENCODING
EOT
);
ok @po, "got the array";
ok $po, "got the po object";

unshift @po, $po;
ok Locale::PO->save_file_fromarray("t/test1.pot.out", \@po), "save file from array";

ok -e "t/test1.pot.out", "the file was created";

SKIP: {
	if ($^O eq 'msys') {
		skip(1, "Comparing POs after a roundtrip fails on msys platform");
	}
	is(read_file("t/test1.pot"), read_file("t/test1.pot.out"), "found no matches - good")
		&& unlink("t/test1.pot.out");
}

################################################################################
#
# Do some roundtrip tests.
#

my $pos = Locale::PO->load_file_asarray("t/test.pot");
ok $pos, "loaded test.pot file";

$out = $pos->[0]->dump;
ok $out, "dumped po object";

is($pos->[1]->loaded_line_number, 16, "got line number of 2nd po entry");

ok Locale::PO->save_file_fromarray("t/test.pot.out", $pos), "save to file";
ok -e "t/test.pot.out", "the file now exists";

SKIP: {
	if ($^O eq 'msys') {
		skip(1, "Comparing POs after a roundtrip fails on msys platform");
	}
	is(read_file("t/test.pot"), read_file("t/test.pot.out"), "found no matches - good")
		&& unlink("t/test.pot.out");
}

################################################################################
#
# Test inline \n.
#

my $str = <<'EOT';
#!/usr/bin/perl
use strict; \
use warnings;

print "Hello,\\n World!\n";
EOT

my $expected = <<'EOT';
msgid ""
"#!/usr/bin/perl\n"
"use strict; \\\n"
"use warnings;\n"
"\n"
"print \"Hello,\\\\n World!\\n\";\n"

EOT

$po = new Locale::PO();
$po->msgid($str);
my $got = $po->dump($str);
is($got, $expected, 'inline newline');

@po = $po;
ok Locale::PO->save_file_fromarray("t/test3.pot.out", \@po), "inline newline save file from array";

$pos = Locale::PO->load_file_asarray("t/test3.pot.out");
ok $pos, "loaded test3.pot.out file";

is($po->msgid, $pos->[0]->msgid, "inline newline reload");

