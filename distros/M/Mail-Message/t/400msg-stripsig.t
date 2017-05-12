#!/usr/bin/env perl
#
# Test stripping signatures
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Body::Construct;
use Mail::Message::Body;

use Test::More tests => 37;

#
# No strip possible
#

my @lines = map { "$_\n" } qw/1 2 3 4 5/;
my $body  = Mail::Message::Body::Lines->new(data => \@lines);

my ($stripped, $sig) = $body->stripSignature;
my $equal = $stripped==$body;
ok($equal, 'stripped 1');

ok(!defined $sig);
cmp_ok($stripped->nrLines, "==", @lines);

my $stripped2 = $body->stripSignature;
$equal = $stripped2==$body;
ok($equal, 'stripped 2');

#
# Simple strip
#

@lines = map { "$_\n" } qw(a b -- sig);
$body  = Mail::Message::Body::Lines->new(data => \@lines);
($stripped, $sig) = $body->stripSignature;
ok($stripped!=$body);
ok($sig!=$body);

cmp_ok($stripped->nrLines, "==", 2);
my @stripped_lines = $stripped->lines;
cmp_ok(@stripped_lines, "==", 2);
is($stripped_lines[0], $lines[0]);
is($stripped_lines[1], $lines[1]);

cmp_ok($sig->nrLines, "==", 2);
my @sig_lines = $sig->lines;
cmp_ok(@sig_lines, "==", 2);
is($sig_lines[0], $lines[2]);
is($sig_lines[1], $lines[3]);

#
# Try signature too large
#

@lines = map { "$_\n" } qw/1 2 3 -- 4 5 6 7 8 9 10/;
$body  = Mail::Message::Body::Lines->new(data => \@lines);
($stripped, $sig) = $body->stripSignature(max_lines => 7);
ok(!defined $sig);
cmp_ok($stripped->nrLines, "==", 11);

($stripped, $sig) = $body->stripSignature(max_lines => 8);
cmp_ok($sig->nrLines, "==", 8);
@sig_lines = $sig->lines;
cmp_ok(@sig_lines, "==", 8);
is($sig_lines[0], $lines[3]);
is($sig_lines[1], $lines[4]);
is($sig_lines[-1], $lines[-1]);

cmp_ok($stripped->nrLines, "==", 3);
@stripped_lines = $stripped->lines;
cmp_ok(@stripped_lines, "==", 3);
is($stripped_lines[0], $lines[0]);
is($stripped_lines[1], $lines[1]);
is($stripped_lines[2], $lines[2]);

#
# Try whole body is signature
#

@lines = map { "$_\n" } qw/-- 1 2 3 4/;
$body  = Mail::Message::Body::Lines->new(data => \@lines);
($stripped, $sig) = $body->stripSignature(max_lines => 7);
cmp_ok($sig->nrLines , "==",  5);
ok(defined $stripped);
cmp_ok($stripped->nrLines , "==",  0);

#
# Try string to find sep
#

@lines = map { "$_\n" } qw/1 2 3 abc 4 5 6/;
$body  = Mail::Message::Body::Lines->new(data => \@lines);
($stripped, $sig) = $body->stripSignature(pattern => 'b');
ok(!defined $sig);

($stripped, $sig) = $body->stripSignature(pattern => 'a');
cmp_ok($sig->nrLines , "==",  4);

#
# Try regexp to find sep
#

@lines = map { "$_\n" } qw/1 2 3 abba baab 4 5 6/;
$body  = Mail::Message::Body::Lines->new(data => \@lines);
($stripped, $sig) = $body->stripSignature(pattern => qr/b{2}/);
ok($sig);
cmp_ok($sig->nrLines , "==",  5);
cmp_ok($stripped->nrLines , "==",  3);

#
# Try code to find sep
#

@lines = map { "$_\n" } qw/1 2 3 ab 4 5 6/;
$body  = Mail::Message::Body::Lines->new(data => \@lines);
($stripped, $sig) = $body->stripSignature(pattern => sub {$_[0] eq "ab\n"});
ok($sig);
cmp_ok($sig->nrLines , "==",  4);
cmp_ok($stripped->nrLines , "==",  3);

