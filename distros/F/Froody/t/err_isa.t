#!/usr/bin/perl

####################################################################
# This test checks to see if errors do indeed 'subclass' correctly
# and that the 'err' function and 'isa_err' methods work in
# Froody::Method
####################################################################

use strict;
use warnings;

use Test::More tests => 22;

use Froody::Error qw(err);

eval { Froody::Error->throw("fred.bar", "wibble!") };

isa_ok($@, "Froody::Error");

ok($@->isa_err(), "empty okay");
ok($@->isa_err(""), "empty str okay");
ok($@->isa_err("fred"), "fred okay");
ok($@->isa_err("fred.bar"), "fred.bar okay");
ok(!$@->isa_err("fred.barr"), "fred.barr not okay");
ok(!$@->isa_err("fred.wibbly"), "fred.wibbly not okay");
ok(!$@->isa_err("freddy"), "freddy not okay");
ok(!$@->isa_err(".bar"), ".bar not okay");

ok(err(), "empty okay");
ok(err(""), "empty str okay");
ok(err("fred"), "fred okay");
ok(err("fred.bar"), "fred.bar okay");
ok(!err("fred.barr"), "fred.barr not okay");
ok(!err("fred.wibbly"), "fred.wibbly not okay");
ok(!err("freddy"), "freddy not okay");
ok(!err(".bar"), ".bar not okay");

eval { };
ok(!err(), "no error is okay");

eval { die "bang" };
ok(err(), "bang is an error");
ok(!err("wibble"), "bang isn't a wibble");
ok(err("unknown"), "bang is unknown");
ok(err("999"),     "bang is unknown");
