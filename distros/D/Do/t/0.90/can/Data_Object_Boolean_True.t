use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

True

=usage

  Data::Object::Boolean::True(); # true

=description

The True function returns a boolean object representing truth.

=signature

True() : Object

=type

function

=cut

# TESTING

use Data::Object::Boolean;

can_ok "Data::Object::Boolean", "True";

my $True = Data::Object::Boolean::True();

isa_ok $True, 'Data::Object::Boolean';

ok 1 and done_testing;
