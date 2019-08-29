use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Array->new([1..4]);

  my $func = Data::Object::Array::Func::Unshift->new(
    arg1 => $data,
    args => [5,6,7]
  );

  my $result = $func->execute;

=description

Executes the function logic and returns the result.

=signature

execute() : Object

=type

method

=cut

# TESTING

use Data::Object::Array;
use Data::Object::Array::Func::Unshift;

can_ok "Data::Object::Array::Func::Unshift", "execute";

my $data;
my $func;

$data = Data::Object::Array->new([1..4]);
$func = Data::Object::Array::Func::Unshift->new(
  arg1 => $data,
  args => [5,6,7]
);

my $result = $func->execute;

is_deeply $result, [5,6,7,1..4];

ok 1 and done_testing;
