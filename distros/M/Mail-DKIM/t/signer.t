#!/usr/bin/perl -I../lib

use strict;
use warnings;
use Test::Simple tests => 31;

use Mail::DKIM::Signer;

my $EXPECTED_RE = qr/CIDMVc94VWhLZ4Ktq2Q05011qBXSO/;

my $tdir = -f "t/test.key" ? "t" : ".";
my $keyfile = "$tdir/test.key";
my $dkim = Mail::DKIM::Signer->new(
		Algorithm => "rsa-sha1",
		Method => "relaxed",
		Domain => "example.org",
		Selector => "test",
		KeyFile => $keyfile);
ok($dkim, "new() works");

my $sample_email = <<END_OF_SAMPLE;
From: jason <jason\@example.org>
Subject: hi there
Comment: what is a comment

this is a sample message
END_OF_SAMPLE
$sample_email =~ s/\n/\015\012/gs;

$dkim->PRINT($sample_email);
$dkim->CLOSE;

my $signature = $dkim->signature;
ok($signature, "signature() works");

print "# signature=" . $signature->as_string . "\n";
ok($signature->as_string =~ /$EXPECTED_RE/,
	"got expected signature value");

# now try a SHA256 signature
$dkim = Mail::DKIM::Signer->new(
		Algorithm => "rsa-sha256",
		Method => "relaxed",
		Domain => "example.org",
		Selector => "test",
		KeyFile => $keyfile);
ok($dkim, "new() works");

$dkim->PRINT($sample_email);
$dkim->CLOSE;

ok($dkim->signature, "signature() works");

# add some headers to the first email
$sample_email = "Received: from x\015\012"
	. "Received: from y\015\012"
	. $sample_email;
$sample_email =~ s/^Comments:.*?$/comments: this can be changed/m;

$dkim = Mail::DKIM::Signer->new(
		Algorithm => "rsa-sha1",
		Method => "relaxed",
		Domain => "example.org",
		Selector => "test",
		Identity => "bob\@example.org",
		Timestamp => time(),
		KeyFile => $keyfile);
ok($dkim, "new() works");

$dkim->PRINT($sample_email);
$dkim->CLOSE;

ok($dkim->signature, "signature() works");
print "# signature=" . $dkim->signature->as_string . "\n";

# check whether the signature includes/excludes certain header fields
my $sigstr = $dkim->signature->as_string;
ok($sigstr =~ /subject/i, "subject was signed");
ok($sigstr =~ /from/i, "from was signed");
ok($sigstr !~ /received/i, "received was excluded");
ok($sigstr !~ /comments/i, "comments was excluded");

# check if the identity got included
ok($sigstr =~ /i=bob\@/, "got expected identity value");
# check if timestamp got included
ok($sigstr =~ /t=\d+/, "found timestamp value");

# add some headers to the previous email for extended tests
$sample_email = "X-Test: 2\015\012"
        . "X-Tests: 2\015\012"
        . "Date: blah\015\012"
        . "X-Test: 1\015\012"
        . "X-Tests: 1\015\012"
	. $sample_email;
$sample_email =~ s/^Comments:.*?$/comments: this can be changed/m;

$dkim = Mail::DKIM::Signer->new(
		Algorithm => "rsa-sha1",
		Method => "relaxed",
		Domain => "example.org",
		Selector => "test",
		Identity => "bob\@example.org",
		Timestamp => time(),
		KeyFile => $keyfile);
ok($dkim, "new() works");

$dkim->extended_headers({ 'Subject' => '+', 'Date' => '0', 'X-Test' => '*', 'X-Tests' => 1, });

$dkim->PRINT($sample_email);
$dkim->CLOSE;

ok($dkim->signature, "signature() works");
print "# signature=" . $dkim->signature->as_string . "\n";

# check whether the signature includes/excludes certain header fields
$sigstr = $dkim->signature->as_string;
ok($sigstr =~ /subject:subject/i, "subject was over signed");
ok($sigstr =~ /x-test:x-test/i, "x-test was all signed");
ok($sigstr =~ /x-tests/i, "x-tests was signed");
ok($sigstr !~ /x-tests:x-tests/i, "x-tests was signed only once");
ok($sigstr =~ /from/i, "from was signed");
ok($sigstr !~ /date/i, "date was excluded");
ok($sigstr !~ /comments/i, "comments was excluded");

# check if the identity got included
ok($sigstr =~ /i=bob\@/, "got expected identity value");
# check if timestamp got included
ok($sigstr =~ /t=\d+/, "found timestamp value");

eval {
$dkim = Mail::DKIM::Signer->new(
		Algorithm => "rsa-sha1",
		Method => "relaxed",
		Domain => "example.org",
		Selector => "test",
		KeyFile => "$tdir/non_existent_file_!!");
};
{
my $E = $@;
print "# $E" if $E;
ok($E, "new() with bogus key file dies as expected");
}

eval {
$dkim = Mail::DKIM::Signer->new(
		Algorithm => "rsa-sha1",
		Method => "relaxed",
		Domain => "example.org",
		Selector => "test",
		KeyFile => "$tdir/unreadable_file");
};
{
my $E = $@;
print "# $E" if $E;
ok($E, "new() with bogus key file dies as expected");
}

{ # TEST signing a message with no header

	my $dkim = Mail::DKIM::Signer->new(
			Algorithm => "rsa-sha1",
			Method => "relaxed",
			Domain => "example.org",
			Selector => "test",
			KeyFile => $keyfile);

	my $sample_email = <<END_OF_SAMPLE;
this message has no header
END_OF_SAMPLE
$sample_email =~ s/\n/\015\012/gs;

	$dkim->PRINT($sample_email);
	$dkim->CLOSE;

	ok($dkim->signature, "signature() works");
}

{ # TEST signing a message with LOTS OF blank lines

	my $dkim = Mail::DKIM::Signer->new(
			Algorithm => "rsa-sha1",
			Method => "relaxed",
			Domain => "example.org",
			Selector => "test",
			KeyFile => $keyfile);

	my $sample_email = <<END_OF_SAMPLE;
From: jason <jason\@example.org>
Subject: hi there
Comment: what is a comment

this is a sample message
END_OF_SAMPLE
	$sample_email .= ("\n" x 50000);
	$sample_email =~ s/\n/\015\012/gs;

	# older, broken, versions of Mail::DKIM will hang here
	$dkim->PRINT($sample_email);
	$dkim->CLOSE;

	ok($dkim->signature, "signature() works");
}

{ # TEST signing a message with obsolete header syntax

	my $dkim = Mail::DKIM::Signer->new(
			Algorithm => "rsa-sha1",
			Method => "relaxed",
			Domain => "example.org",
			Selector => "test",
			KeyFile => $keyfile);

	my $sample_email = <<END_OF_SAMPLE;
From : jason <jason\@example.org>
Subject: hi there
Comment: what is a comment

this is a sample message
END_OF_SAMPLE
	$sample_email =~ s/\n/\015\012/gs;
	$dkim->PRINT($sample_email);
	$dkim->CLOSE;

	ok($dkim->signature, "signature() works");

	my $sigstr = $dkim->signature->as_string;
	ok($sigstr =~ /subject/i, "subject was signed");
	ok($sigstr =~ /from/i, "from was signed");
}
