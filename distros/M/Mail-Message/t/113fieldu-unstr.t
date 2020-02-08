#!/usr/bin/env perl
#
# Test processing of unstructured fields
#

use strict;
use warnings;
use utf8;

use Mail::Message::Test;
use Mail::Message::Field::Unstructured;

use Test::More tests => 32;

my $mmff = 'Mail::Message::Field::Full';
my $mmfu = 'Mail::Message::Field::Unstructured';

#
# Test construction with simple body
#

my $a = $mmfu->new('a', 'new');
ok(defined $a,                          "Created simplest version");
isa_ok($a, $mmfu);
isa_ok($a, $mmff);
is($a->name, 'a',                       "Name of a");

is($a->unfoldedBody, 'new',             "Unfolded body a");
my @al = $a->foldedBody;
cmp_ok(@al, '==', 1,                    "Folded body of a");
is($al[0], " new\n");

my $b = $mmfu->new('b');
ok(defined $b,                          "No body specified: later");

#
# LINE without new lines (no folds)
#

$b = $mmfu->new('b: new');
ok(defined $b,                          "Created b with body split");
isa_ok($b, $mmfu);
isa_ok($b, $mmff);
is($b->name, 'b',                       "Name of b");

is($b->unfoldedBody, 'new',             "Unfolded body b");
my @bl = $b->foldedBody;
cmp_ok(@bl, '==', 1,                    "Folded body of b");
is($bl[0], " new\n");

#
# LINE with new-lines (folds)
#

my $c = $mmfu->new("c: new\n line\n");
ok(defined $c,                          "Created c with body split");
isa_ok($c, $mmfu);
isa_ok($c, $mmff);
is($c->name, 'c',                       "Name of c");

is($c->unfoldedBody, 'new line',        "Unfolded body c");
my @cl = $c->foldedBody;
cmp_ok(@cl, '==', 2,                    "Folded body of c");
is($cl[0], " new\n",                    "Folded c line 1");
is($cl[1], " line\n",                   "Folded c line 2");

#
# Test encoding of line with separate body
#

my $d = $mmfu->new("d", "a\x{E4}b", charset => 'iso-8859-1');
ok(defined $d,                          "Created d with included stranger");
isa_ok($d, $mmfu);
is($d->name, 'd',                       "Name of d");

is($d->unfoldedBody, '=?iso-8859-1?q?a=E4b?=', "Unfolded body d");

my @dl = $d->foldedBody;
cmp_ok(@dl, '==', 1,                    "Folded body of d");

is($dl[0], " =?iso-8859-1?q?a=E4b?=\n", "Folded d line 0");

is($d->decodedBody, "a\x{E4}b");

#
# Test folding of very long lines with unicode and fieldname
# added 3.002

my $e = $mmfu->new(Subject => 'Ẇåƫ įś Ûņįĉóɖé ¿ Ŵąť ïŝ Ḝṋɕòḑǐꞑĝ, Ẇåƫ įś Ûņįĉóɖé ¿ Ŵąť ïŝ Ḝṋɕòḑǐꞑĝ Ẇåƫ įś Ûņįĉóɖé ¿ Ŵąť ïŝ Ḝṋɕòḑǐꞑĝ, Ẇåƫ įś Ûņįĉóɖé ¿ Ŵąť ïŝ Ḝṋɕòḑǐꞑĝ', charset => 'utf-8');
ok defined $e, 'folding';
is $e->string, <<_E_ENCODED;
Subject: =?utf-8?q?=E1=BA=86=C3=A5=C6=AB_=C4=AF=C5=9B_=C3=9B=C5=86=C4=AF?=
 =?utf-8?q?=C4=89=C3=B3=C9=96=C3=A9_=C2=BF_=C5=B4=C4=85=C5=A5_=C3=AF=C5=9D?=
 =?utf-8?q?_=E1=B8=9C=E1=B9=8B=C9=95=C3=B2=E1=B8=91=C7=90=EA=9E=91=C4=9D?=
 =?utf-8?q?=2C_=E1=BA=86=C3=A5=C6=AB_=C4=AF=C5=9B_=C3=9B=C5=86=C4=AF=C4=89?=
 =?utf-8?q?=C3=B3=C9=96=C3=A9_=C2=BF_=C5=B4=C4=85=C5=A5_=C3=AF=C5=9D_?=
 =?utf-8?q?=E1=B8=9C=E1=B9=8B=C9=95=C3=B2=E1=B8=91=C7=90=EA=9E=91=C4=9D_?=
 =?utf-8?q?=E1=BA=86=C3=A5=C6=AB_=C4=AF=C5=9B_=C3=9B=C5=86=C4=AF=C4=89?=
 =?utf-8?q?=C3=B3=C9=96=C3=A9_=C2=BF_=C5=B4=C4=85=C5=A5_=C3=AF=C5=9D_?=
 =?utf-8?q?=E1=B8=9C=E1=B9=8B=C9=95=C3=B2=E1=B8=91=C7=90=EA=9E=91=C4=9D=2C?=
 =?utf-8?q?_=E1=BA=86=C3=A5=C6=AB_=C4=AF=C5=9B_=C3=9B=C5=86=C4=AF=C4=89?=
 =?utf-8?q?=C3=B3=C9=96=C3=A9_=C2=BF_=C5=B4=C4=85=C5=A5_=C3=AF=C5=9D_?=
 =?utf-8?q?=E1=B8=9C=E1=B9=8B=C9=95=C3=B2=E1=B8=91=C7=90=EA=9E=91=C4=9D?=
_E_ENCODED
