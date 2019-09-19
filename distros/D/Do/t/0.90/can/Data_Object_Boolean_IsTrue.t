use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

IsTrue

=usage

  Data::Object::Boolean::IsTrue(); # true
  Data::Object::Boolean::IsTrue($value); # true/false

=description

The IsTrue function returns a boolean object representing truth if no
arugments are passed, otherwise this function will return a boolean object
based on the argument provided.

=signature

IsTrue() : Object

=type

function

=cut

# TESTING

use Data::Object::Boolean;

can_ok "Data::Object::Boolean", "IsTrue";

my $True = Data::Object::Boolean::True();
my $IsTrue = Data::Object::Boolean::IsTrue($True);

isa_ok $IsTrue, 'Data::Object::Boolean';
is $IsTrue, 1;

ok 1 and done_testing;
