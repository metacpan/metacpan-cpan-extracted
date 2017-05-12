#!perl

use Test::More tests => 3;

use strict;
use warnings;

use Test::Exception;

use JSPL;

my $rt1 = new JSPL::Runtime();
my $cx1 = $rt1->create_context();

$cx1->bind_class(
    name => "foo",
    constructor => sub { bless {}; },
    package => 'main',
);

ok($cx1->eval(q{
  foo.prototype.bar = function() { return 1 };
  1;
}), "Assign to prototype ok");

is($cx1->eval(q/ ( new foo() ).bar() /), 1, "can call prototype methods");

# This is only testing SM
is($cx1->eval(q|
    Date.prototype.foo = function() { return 6 };
    ( new Date() ).foo();
   |),
   6, "can mess with prototypes of built-ins");

