#!/usr/bin/perl

use strict;
use warnings;
use Test::Simple tests => 4;

use Mail::DKIM::Canonicalization::simple;
use Mail::DKIM::Signature;

my $dkim_signature = "DKIM-Signature: h=from:subject; s=test; d=example.org; b=";
my $signature = Mail::DKIM::Signature->parse($dkim_signature);
ok($signature, "create signature works");

my $method = Mail::DKIM::Canonicalization::simple->new(
		Signature => $signature);
ok($method, "new() works");

my @tmp_headers = (
	"from :\tJason\015\012",
	"Subject:  this is the\015\012  subject\015\012",
	);

$method->add_header($tmp_headers[0]);
$method->add_header($tmp_headers[1]);
$method->finish_header(Headers => \@tmp_headers);

$method->add_body("This is the body.\015\012");
$method->add_body("Another line of the body.\015\12");
$method->finish_body;

$method->finish_message;
ok(1, "finish_message() works");

my $expected = "from :	Jason
Subject:  this is the
  subject
This is the body.
Another line of the body.

$dkim_signature";
$expected =~ s/\n/\015\012/gs;

ok($method->result eq $expected, "got expected result");

# uncomment this if you're not getting the expected result
#print ">" . $method->result . "<\n";
#print ">" . $expected . "<\n";
