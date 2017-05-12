#!/usr/bin/env perl
#
# Test processing of general structured fields
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Field::Structured;

use Test::More tests => 64;

my $mmff = 'Mail::Message::Field::Full';
my $mmfs = 'Mail::Message::Field::Structured';
my $mmfa = 'Mail::Message::Field::Attribute';

#
# Test construction with simple body
#

my $a = $mmfs->new('a', 'new');
ok(defined $a,                          "Created simplest version");
isa_ok($a, $mmfs);
isa_ok($a, $mmff);
is($a->name, 'a',                       "Name of a");

is($a->unfoldedBody, 'new',             "Unfolded body a");
my @al = $a->foldedBody;
cmp_ok(@al, '==', 1,                    "Folded body of a");
is($al[0], " new\n");

my $b = $mmfs->new('b');
ok(defined $b,                          "No body specified: later");

#
# LINE without new lines (no folds)
#

$b = $mmfs->new('b: new');
ok(defined $b,                          "Created b with body split");
isa_ok($b, $mmfs);
isa_ok($b, $mmff);
is($b->name, 'b',                       "Name of b");

is($b->unfoldedBody, 'new',             "Unfolded body b");
my @bl = $b->foldedBody;
cmp_ok(@bl, '==', 1,                    "Folded body of b");
is($bl[0], " new\n");

#
# LINE with new-lines (folds)
#

my $c = $mmfs->new("c: new\n line\n");
ok(defined $c,                          "Created c with body split");
isa_ok($c, $mmfs);
isa_ok($c, $mmff);
is($c->name, 'c',                       "Name of c");

is($c->unfoldedBody, 'new line',        "Unfolded body c");
my @cl = $c->foldedBody;
cmp_ok(@cl, '==', 2,                    "Folded body of c");
is($cl[0], " new\n",                    "Folded c line 1");
is($cl[1], " line\n",                   "Folded c line 2");

#
# Constructing
#

my $d = $mmfs->new('d');
ok(defined $d,                          "Created d");
is($d->unfoldedBody, "",                "Empty body");
is($d->foldedBody, " \n",               "Empty body");

is($d->datum('text/html'), 'text/html', "Set datum");
$d->beautify;  # required to re-generate
is($d->produceBody, "text/html",        "Check datum");
is($d->unfoldedBody, "text/html");
is($d->foldedBody, " text/html\n");

ok(! defined $d->attribute('unknown'),  "No attributes yet");
cmp_ok(scalar $d->attributes, '==', 0);

my $da = $d->attribute(filename => 'virus.exe');
isa_ok($da, 'Mail::Message::Field::Attribute');
is($d->produceBody, 'text/html; filename="virus.exe"');
is($d->unfoldedBody, 'text/html; filename="virus.exe"');
is($d->foldedBody, qq# text/html; filename="virus.exe"\n#);

#
# Parsing
#

my $body = "(comment1)bod(aa)y(comment2); (comment3)attr1=aaa(comment4); attr2=\"b\"; attr3='c'";

my $e = $mmfs->new("e: $body\n");
ok(defined $e, "field with attributes");
is($e->datum, 'body',                   "Check datum");

my @attrs = $e->attributes;
cmp_ok(scalar @attrs, '==', 3,          "All attributes");

ok(defined $e->attribute('attr1'),      "attr1 exists");
isa_ok($e->attribute('attr1'), $mmfa);
is($e->attribute('attr1')->value, 'aaa',"attr1 value");

ok(defined $e->attribute('attr2'),      "attr2 exists");
isa_ok($e->attribute('attr2'), $mmfa);
is($e->attribute('attr2')->value, 'b',  "attr2 value");

ok(defined $e->attribute('attr3'),      "attr3 exists");
isa_ok($e->attribute('attr3'), $mmfa);
is($e->attribute('attr3')->value, 'c',  "attr3 value");

is($e->unfoldedBody, "$body",           "unfolded not changed");
is($e->foldedBody, " $body\n",          "folded not changed");

$e->beautify;
is($e->unfoldedBody, "body; attr1=aaa; attr2=b; attr3='c'",
                                        "unfolded beautyfied");
is($e->foldedBody, " body; attr1=aaa; attr2=b; attr3='c'\n",
                                        "folded beautyfied");

#
## errors
#

my $f = $mmfs->new('f: c; a="missing quote');  # bug report #31017
ok(defined $f, 'missing quote');
is($f->unfoldedBody, 'c; a="missing quote');
is($f->foldedBody, " c; a=\"missing quote\n");

my $fa = $f->attribute('a');
ok(defined $fa, 'f attribute a');
is($fa->string, '; a=missing quote');
is($fa->value, 'missing quote');

my $g = $mmfs->new('g: c; a="with []"');      # bug report #31912
ok(defined $g, '[]');
my $ga = $g->attribute('a');
ok(defined $ga);
is($ga->value, 'with []');

my $gb = $mmfs->new('g: c; filename=xxxx[1].pif');
ok(defined $gb, 'xxxx[1].pif');
my $gc = $gb->attribute('filename');
ok(defined $gc);
is($gc->value, 'xxxx[1].pif');
