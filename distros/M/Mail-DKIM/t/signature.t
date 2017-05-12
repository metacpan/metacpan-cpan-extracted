#!/usr/bin/perl -I../lib

use strict;
use warnings;
use Test::Simple tests => 12;

use Mail::DKIM::Signature;
use Mail::DKIM::TextWrap;

my $signature = Mail::DKIM::Signature->new();
ok($signature, "new() works");

$signature->algorithm("rsa-sha1");
ok($signature->algorithm eq "rsa-sha1", "algorithm() works");

$signature->canonicalization("relaxed", "simple");
my ($header_can, $body_can) = $signature->canonicalization;
ok($header_can eq "relaxed", "canonicalization() works (I)");
ok($body_can eq "simple", "canonicalization() works (II)");
my $combined = $signature->canonicalization;
ok($combined eq "relaxed/simple", "canonicalization() works (III)");

$signature->canonicalization("simple/relaxed");
ok($signature->canonicalization eq "simple/relaxed",
	"canonicalization() works (IV)");

my $unparsed = "DKIM-Signature: a=rsa-sha1; c=relaxed";
$signature = Mail::DKIM::Signature->parse($unparsed);
ok($signature, "parse() works (I)");

$unparsed = "DKIM-Signature: a 	 = 	 rsa-sha1;  c 	 = 	 simple/simple;
	d 	 = 	example.org ;
 h 	 = 	 Date : From : MIME-Version : To : Subject : Content-Type :
Content-Transfer-Encoding; s 	 = 	 foo;
 b=aqanVhX/f1gmXSdVeX3KdmeKTZb1mkj1y111tZRp/8tXWX/srpGu2SJ/+O06fQv8YtgP0BrSRpEC
 WEtFgMHcDf0ZFLQgtm0f7vPBO98vDtB7dpDExzHyTsK9rxm8Cf18";
$signature = Mail::DKIM::Signature->parse($unparsed);
ok($signature, "parse() works (II)");
ok($signature->domain eq "example.org", "parse() correctly handles spaces");

print "#BEFORE->\n" . $signature->as_string . "\n";
$signature->prettify_safe;
print "#SAFE--->\n" . $signature->as_string . "\n";
$signature->prettify;
print "#PRETTY->\n" . $signature->as_string . "\n";
check_pretty($signature->as_string);


$unparsed = "DKIM-Signature: v=1; a=rsa-sha256; c=simple/simple; d=ijs.si; s=jakla2;\n\tt=1225813757; bh=g3zLYH4xKxcPrHOD18z9YfpQcnk/GaJedfustWU5uGs=; b=";
$signature = Mail::DKIM::Signature->parse($unparsed);
ok($signature, "parse() works (III)");

print "#BEFORE->\n" . $signature->as_string . "\n";
$signature->data("blah");
print "#AFTER-->\n" . $signature->as_string . "\n";
my $first_part_1 = ($signature->as_string =~ /^(.*?b=)/s)[0];
$signature->prettify_safe;
print "#PRETTY->\n" . $signature->as_string . "\n";
my $first_part_2 = ($signature->as_string =~ /^(.*?b=)/s)[0];
ok($first_part_1 eq $first_part_2, "signature preserved with prettify_safe");

sub check_pretty
{
	my $str = shift;
	my @lines = split /\n/s, $str;

	my $any_long_lines = grep { length($_) > 72 } @lines;
	ok(!$any_long_lines, "any lines exceed 72 characters");
}
