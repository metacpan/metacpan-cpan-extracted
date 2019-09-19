use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

IsFalse

=usage

  Data::Object::Boolean::IsFalse(); # false
  Data::Object::Boolean::IsFalse($value); # true/false

=description

The IsFalse function returns a boolean object representing false if no
arugments are passed, otherwise this function will return a boolean object
based on the argument provided.

=signature

IsFalse(Maybe[Any] $arg) : Object

=type

function

=cut

# TESTING

use Data::Object::Boolean;

can_ok "Data::Object::Boolean", "IsFalse";

my $False = Data::Object::Boolean::False();
my $IsFalse = Data::Object::Boolean::IsFalse($False);

isa_ok $IsFalse, 'Data::Object::Boolean';
is $IsFalse, 1;

ok 1 and done_testing;
