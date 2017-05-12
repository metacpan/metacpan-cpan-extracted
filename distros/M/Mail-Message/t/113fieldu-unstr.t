#!/usr/bin/env perl
#
# Test processing of unstructured fields
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Field::Unstructured;

use Test::More tests => 30;

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
