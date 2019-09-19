use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

False

=usage

  Data::Object::Boolean::False(); # false

=description

The False function returns a boolean object representing false.

=signature

False() : Object

=type

function

=cut

# TESTING

use Data::Object::Boolean;

can_ok "Data::Object::Boolean", "False";

my $False = Data::Object::Boolean::False();

isa_ok $False, 'Data::Object::Boolean';

ok 1 and done_testing;
