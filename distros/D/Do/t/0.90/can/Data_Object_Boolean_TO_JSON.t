use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TO_JSON

=usage

  Data::Object::Boolean::TO_JSON($true); # \1
  Data::Object::Boolean::TO_JSON($false); # \0

=description

The TO_JSON function returns a scalar ref representing truthiness or falsiness
based on the arguments passed. This function is commonly used by JSON encoders
and instructs them on how they should represent the value.

=signature

TO_JSON(Any $arg) : Ref['SCALAR']

=type

function

=cut

# TESTING

use Data::Object::Boolean;

can_ok "Data::Object::Boolean", "TO_JSON";

my $ref;

my $True = Data::Object::Boolean::True();
my $False = Data::Object::Boolean::False();

$ref = Data::Object::Boolean::TO_JSON($True);
isa_ok $ref, 'SCALAR';
is $$ref, 1;

$ref = Data::Object::Boolean::TO_JSON($False);
isa_ok $ref, 'SCALAR';
is $$ref, 0;

ok 1 and done_testing;
