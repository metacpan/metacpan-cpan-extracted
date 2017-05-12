#!/usr/bin/perl

#########################################################################
# This does basic checks on a method, can we get and set the basic values
# and do we get errors in the case that we do the wrong thing?
#########################################################################

use strict;
use warnings;

use Test::Exception;

# start the tests
use Test::More tests => 23;

use Froody::Error qw(err);

use_ok("Froody::Method");
my $method = Froody::Method->new();
isa_ok($method, "Froody::Method", "constructor test");

#####
# check setting the full name

lives_ok {
  $method->full_name("fred");
} "we now allow no dots";

throws_ok {
  $method->full_name("fred,bar");
} "Froody::Error", "illegal chars in full name";
ok(err("perl.methodcall.param"), "correct error type") or diag $@;

lives_ok {
  $method->full_name("fred.wilma");
} "we now allow less dots";

lives_ok {
  $method->full_name("fred.wilma.BAR");
} "upper and lower case chars allowed";

lives_ok {
  $method->full_name("fred.wilma_BAR99");
} "upper and lower case chars, numbers and underscores allowed";

lives_ok {
  $method->full_name("fred.wilma.bar");
} "set full name without dieing";

is($method->full_name, "fred.wilma.bar", "full name returned okay");

####
# check getting the parts back

is($method->name,   "bar", "name");
is($method->module, "Fred::Wilma", "module");
is($method->service,"fred", "service");
is($method->object, "Wilma", "object");

####
# check we can't set those

foreach (qw(name module service object))
 { dies_ok { $method->$_("some_value") } "can't set $_" }
 
####
# check the invoker

is($method->invoker, undef, "no invoker");

throws_ok {
  $method->call("fred.wilma.bar99", {} );
} "Froody::Error", "can't call without an invoker";
ok(err("froody.invoke.noinvoker"), "correct error type") or diag $@;;

throws_ok {
  $method->invoker("Fred");
} "Froody::Error", "invokers must be of the right class";
ok(err("perl.methodcall.param"), "correct error type") or diag $@;;
