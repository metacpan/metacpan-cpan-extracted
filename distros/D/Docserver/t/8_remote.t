#!/usr/bin/perl -w

my $server;

if (not open CONFIG, 'testcfg') {
	print "1..0\nConfiguration failed, probably, no remote testing.\n";
	exit;
}

while (<CONFIG>) {
	if (/^remote_server\s*:\s*(\S+)/) {
		$server = $1;
		last;
	}
}
close CONFIG;

if (not defined $server or $server eq '') {
	print "1..0\nNo remote testing configured, fine.\n";
	exit;
}

my ($remote_server, $remote_port) = ($server =~ /^(.+):(\d+)$/);
if (not defined $remote_server ne '') {
	print "1..0\nBroken configuration (remote_server $server).\n";
	exit;
}

print "1..3\n";

print "Will try to contact the remote docserver at $remote_server:$remote_port.\n";
my $version = `$^X -Ilib bin/docclient.pl --server_version --server=$remote_server --port=$remote_port`;
if (defined $version and $version =~ /^This is/) {
	print "Got: $version\nok 1\n";
} else {
	print "No, didn't get any reasonable response, no point in continuing.\nnot ok 1\n";
	exit;
}

my ($command, $got, $expected);

unlink 't/testremote.txt';
$command = "$^X -Ilib bin/docclient.pl --raw --out_format=txt --server=$remote_server --port=$remote_port t/test.doc > t/testremote.txt";
print "Will run command\n$command\nto test conversion to plain text on remote docserver.\n";

system $command;

if (-f 't/testremote.txt' and -s 't/testremote.txt') {
	print "The conversion seems to have run fine.\n";
	print "ok 2\n";

	if (open GOT, 't/testremote.txt') {
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


