use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Array->new([1..5]);

  my $func = Data::Object::Array::Func::Keyed->new(
    arg1 => $data,
    args => ['a'..'d']
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
use Data::Object::Array::Func::Keyed;

can_ok "Data::Object::Array::Func::Keyed", "execute";

my $data;
my $func;

$data = Data::Object::Array->new([1..5]);
$func = Data::Object::Array::Func::Keyed->new(
  arg1 => $data,
  args => ['a'..'d']
);

my $result = $func->execute;

is_deeply $result, {a=>1,b=>2,c=>3,d=>4};

ok 1 and done_testing;
