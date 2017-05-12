#!/usr/bin/perl

#########################################################################
# This does basic checks on Froody::Structure,
# can we get and set the basic values and do we get errors in the case
# that we do the wrong thing?
#########################################################################

use strict;
use warnings;

use Test::Exception;
use Froody::Error qw(err);

# start the tests
use Test::More tests => 18;

use_ok("Froody::Structure");

###
# constructor test

my $s = Froody::Structure->new();
isa_ok($s, "Froody::Structure");

###
# store the structure?

ok($s->can("structure"), "has structure method");
my $fred = { foo => "bar" };
$s->structure($fred);
is_deeply($s->structure, $fred, "structures compare okay");

# can we inadvertantly alter the structure?

$fred->{foo} = "oof";
is_deeply($s->structure, { foo => "bar" }, "structures compare okay");

# can we futz with the structure after the fact though?

$s->structure->{foo} = "wibble";
is_deeply($s->structure, { foo => "wibble" }, "structures compare okay");

###
# example resposne

use Froody::Response::String;
my $response = Froody::Response::String->new();

ok($s->can("example_response"), "has example_response method");
$s->example_response($response);
is($s->example_response, $response, "structures compare okay");

dies_ok { $s->example_response("random string") } "random string resposne";
ok(err("perl.methodcall.param"), " right error");

dies_ok { $s->example_response(bless {}, "fish") } "random object resposne";
ok(err("perl.methodcall.param"), " right error");

###
# check that our regex converter works

my $regex = Froody::Structure->match_to_regex("fred.bar.*");

is(ref($regex), "Regexp", "returned a regex");
like("fred.bar.barney", $regex, "re test 1");
like("fred.bar.wibble", $regex, "re test 2");
unlike("fred.foo.barney", $regex, "re test 3");
unlike("fred.bar.barney.foo", $regex, "re test 4");

dies_ok { Froody::Method->match_to_regex("()"); } "protect against weird re"
