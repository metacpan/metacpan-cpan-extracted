#!/usr/bin/perl -I../lib

use strict;
use warnings;
use Test::Simple tests => 9;

use Mail::DKIM::ARC::Signer;

my $tdir    = -f "t/test.key" ? "t" : ".";
my $keyfile = "$tdir/test.key";
my $arc     = Mail::DKIM::ARC::Signer->new(
    Algorithm => "rsa-sha256",
    Domain    => "example.org",
    Selector  => "test",
    Chain     => "ar",
    KeyFile   => $keyfile
);
ok($arc, "new() works");

## Chain ar, no AR header

my $sample_email = <<END_OF_SAMPLE;
From: jason <jason\@example.org>
Subject: hi there
Comment: what is a comment

this is a sample message
END_OF_SAMPLE
$sample_email =~ s/\n/\015\012/gs;

$arc->PRINT($sample_email);
$arc->CLOSE;

ok($arc->result() eq 'skipped', 'result() is skipped');

## Chain ar, not my AR header

$sample_email = <<END_OF_SAMPLE;
Authentication-Results: example.com; none
From: jason <jason\@example.org>
Subject: hi there
Comment: what is a comment

this is a sample message
END_OF_SAMPLE
$sample_email =~ s/\n/\015\012/gs;

$arc = Mail::DKIM::ARC::Signer->new(
    Algorithm => "rsa-sha256",
    Domain    => "example.org",
    Selector  => "test",
    Chain     => "ar",
    KeyFile   => $keyfile
);

$arc->PRINT($sample_email);
$arc->CLOSE;

ok($arc->result() eq 'skipped', 'result() is skipped');

## Chain ar, AR header none

$sample_email = <<END_OF_SAMPLE;
Authentication-Results: example.org; none
From: jason <jason\@example.org>
Subject: hi there
Comment: what is a comment

this is a sample message
END_OF_SAMPLE
$sample_email =~ s/\n/\015\012/gs;

$arc = Mail::DKIM::ARC::Signer->new(
    Algorithm => "rsa-sha256",
    Domain    => "example.org",
    Selector  => "test",
    Chain     => "ar",
    KeyFile   => $keyfile
);

$arc->PRINT($sample_email);
$arc->CLOSE;

ok($arc->result() eq 'sealed', 'result() is sealed');
my ($as) = $arc->as_strings();
ok($as =~ m/\bcv=none\b/, 'AS has cv=none');

## Chain ar, AR header pass

$sample_email = <<END_OF_SAMPLE;
Authentication-Results: example.org; dkim=none (no signatures); arc=pass (something or other)
From: jason <jason\@example.org>
Subject: hi there
Comment: what is a comment

this is a sample message
END_OF_SAMPLE
$sample_email =~ s/\n/\015\012/gs;

$arc = Mail::DKIM::ARC::Signer->new(
    Algorithm => "rsa-sha256",
    Domain    => "example.org",
    Selector  => "test",
    Chain     => "ar",
    KeyFile   => $keyfile
);

$arc->PRINT($sample_email);
$arc->CLOSE;

ok($arc->result() eq 'sealed', 'result() is sealed');
($as) = $arc->as_strings();
ok($as =~ m/\bcv=pass\b/, 'AS has cv=pass');

## Chain ar, AR header fail

$sample_email = <<END_OF_SAMPLE;
Authentication-Results: example.org;
  arc=fail (bad something);
  spf=pass smtp.mailfrom="jason\@example.net";
From: jason <jason\@example.org>
Subject: hi there
Comment: what is a comment

this is a sample message
END_OF_SAMPLE
$sample_email =~ s/\n/\015\012/gs;

$arc = Mail::DKIM::ARC::Signer->new(
    Algorithm => "rsa-sha256",
    Domain    => "example.org",
    Selector  => "test",
    Chain     => "ar",
    KeyFile   => $keyfile
);

$arc->PRINT($sample_email);
$arc->CLOSE;

ok($arc->result() eq 'sealed', 'result() is sealed');
($as) = $arc->as_strings();
ok($as =~ m/\bcv=fail\b/, 'AS has cv=fail');
