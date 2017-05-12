#!/usr/bin/perl -w

my $PIDFILE = 'docserver.pid';

if (not -f $PIDFILE) {
	print "1..0\nNo docserver seems to be running, OK.\n";
	exit;
}

print "1..9\n";

my $version = `$^X -Ilib bin/docclient.pl --server_version`;
if (defined $version and $version =~ /^This is/) {
	print "Got: $version";
	print "ok 1\n";
} else {
	print "No, didn't get any reasonable response, no point in continuing.\nnot ok 1\n";
        exit;
}

my ($command, $got, $expected);

unlink 't/testdoc.txt';
$command = "$^X -Ilib bin/docclient.pl --raw --out_format=txt t/test.doc > t/testdoc.txt";
print "Will run command\n$command\nto test conversion to plain text.\n";

system $command;

if (-f 't/testdoc.txt' and -s 't/testdoc.txt') {
	print "The conversion seems to have run fine.\n";
	print "ok 2\n";

	if (open GOT, 't/testdoc.txt') {
		$got = join '', <GOT>;
		close GOT;
		$got =~ s/^\s*|\s*$//g;
		$got =~ s/\s+/ /g;
	}
	if (open EXPECTED, 't/testdoc.exp') {
		$expected = join '', <EXPECTED>;
		close EXPECTED;
		$expected =~ s/^\s*|\s*$//g;
		$expected =~ s/\s+/ /g;
	}

	if ($got ne $expected) {
		print "But expected\n$expected\nand got\n$got\nnot ok 3\n";
	} else {
		print "And the result is fine.\nok 3\n";
	}
} else {
	print "Conversion failed, for one reason or another.\nnot ok 2\nnot ok 3\n";
}

unlink 't/testdoc.txt1';
$command = "$^X -Ilib bin/docclient.pl --raw --out_format=txt1 t/test.doc > t/testdoc.txt1";
print "Will run command\n$command\nto test conversion to Text with Layout.\n";

system $command;

if (-f 't/testdoc.txt1' and -s 't/testdoc.txt1') {
	print "The conversion seems to have run fine.\n";
	print "ok 4\n";

	if (open GOT, 't/testdoc.txt1') {
		$got = join '', <GOT>;
		close GOT;
		$got =~ s/^\s*|\s*$//g;
		$got =~ s/\s+/ /g;
	}
	if (open EXPECTED, 't/testdoc.exp') {
		$expected = join '', <EXPECTED>;
		close EXPECTED;
		$expected =~ s/^\s*|\s*$//g;
		$expected =~ s/\s+/ /g;
	}

	if ($got ne $expected) {
		print "But expected\n$expected\nand got\n$got\nnot ok 5\n";
	} else {
		print "And the result is fine.\nok 5\n";
	}
} else {
	print "Conversion failed, for one reason or another.\nnot ok 4\nnot ok 5\n";
}

unlink 't/testdoc.html';
$command = "$^X -Ilib bin/docclient.pl --raw --out_format=html t/test.doc > t/testdoc.html";
print "Will run command\n$command\nto test conversion to HTML.\n";

system $command;

if (-f 't/testdoc.html' and -s 't/testdoc.html') {
	print "The conversion seems to have run fine.\n";
	print "ok 6\n";

	if (open GOT, 't/testdoc.html') {
		$got = join '', <GOT>;
		close GOT;
	}

	if ($got =~ m!<HTML.*?<BODY.*?Krtku krtku.*?</BODY>.*?</HTML>!is) {
		print "And the result is fine.\nok 7\n";
	} else {
		print "But the content doesn't seem to be HTML with our document.\nnot ok 7\n";
	}
} else {
	print "Conversion failed, for one reason or another.\nnot ok 6\nnot ok 7\n";
}

unlink 't/testdoc.ps';
$command = "$^X -Ilib bin/docclient.pl --out_format=ps t/test.doc > t/testdoc.ps";
print "Will run command\n$command\nto test conversion to PostScript.\n";

system $command;

if (-f 't/testdoc.ps' and -s 't/testdoc.ps') {
	print "The conversion seems to have run fine.\n";
	print "ok 8\n";

	if (open GOT, 't/testdoc.ps') {
		$got = join '', <GOT>;
		close GOT;
	}

	if ($got =~ m#^%!PS-Adobe.*?(Krtku krtku|dup 1 /K put\sdup 2 /r put\sdup 3 /t put\sdup 4 /e put\sdup 5 /k put).*%%EOF#s) {
		print "And the result is fine.\nok 9\n";
	} else {
		print "But the content doesn't seem to be PS with our document.\nnot ok 9\n";
	}
} else {
	print "Conversion failed, for one reason or another.\nnot ok 8\nnot ok 9\n";
}

