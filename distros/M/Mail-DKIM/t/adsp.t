#!/usr/bin/perl -I../blib/lib

use strict;
use warnings;
use Test::More tests => 6;

use Mail::DKIM::Verifier;
use Mail::DKIM::AuthorDomainPolicy;

my $message = <<'END';
From: Jason Long <jlong@messiah.edu>
Sender: George <george@example.org>
Subject: test message

This message has no signature. 
END
$message =~ s/\n/\015\012/gs;

my $dkim = Mail::DKIM::Verifier->new();
$dkim->PRINT($message);
$dkim->CLOSE;
ok($dkim, "created verifier");

my $policy;
$policy = Mail::DKIM::AuthorDomainPolicy->new();
ok($policy, "new() works");

$policy = Mail::DKIM::AuthorDomainPolicy->parse(
		String => "dkim=all",
		Domain => "messiah.edu",
		);
ok($policy, "parse() works");

my $result;
$result = $policy->apply($dkim);
print "# $result\n";
ok($result eq "neutral", "got expected result");

$policy = Mail::DKIM::AuthorDomainPolicy->parse(
		String => "dkim=discardable",
		Domain => "messiah.edu",
		);
ok($policy, "parse() works");

$result = $policy->apply($dkim);
print "# $result\n";
ok($result eq "reject", "got expected result");
