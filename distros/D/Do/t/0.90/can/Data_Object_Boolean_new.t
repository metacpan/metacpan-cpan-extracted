use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $bool;

  $bool = Data::Object::Boolean->new; # false
  $bool = Data::Object::Boolean->new(1); # true
  $bool = Data::Object::Boolean->new(0); # false
  $bool = Data::Object::Boolean->new(''); # false
  $bool = Data::Object::Boolean->new(undef); # false

=description

The new method returns a boolean object based on the value of the argument
provided.

=signature

new(Any $arg) : Object

=type

method

=cut

# TESTING

use Data::Object::Boolean;

can_ok "Data::Object::Boolean", "new";

my $bool;

$bool = Data::Object::Boolean->new; # false
isa_ok $bool, 'Data::Object::Boolean';
is $bool, 0;

$bool = Data::Object::Boolean->new(1); # true
isa_ok $bool, 'Data::Object::Boolean';
is $bool, 1;

$bool = Data::Object::Boolean->new(0); # false
isa_ok $bool, 'Data::Object::Boolean';
is $bool, 0;

$bool = Data::Object::Boolean->new(''); # false
isa_ok $bool, 'Data::Object::Boolean';
is $bool, 0;

$bool = Data::Object::Boolean->new(undef); # false
isa_ok $bool, 'Data::Object::Boolean';
is $bool, 0;

ok 1 and done_testing;
