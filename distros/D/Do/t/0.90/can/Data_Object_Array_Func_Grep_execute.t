use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Array->new([1..4]);

  my $func = Data::Object::Array::Func::Grep->new(
    arg1 => $data,
    arg2 => sub { $_[0] > 2 }
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
use Data::Object::Array::Func::Grep;

can_ok "Data::Object::Array::Func::Grep", "execute";

my $data;
my $func;

$data = Data::Object::Array->new([1..4]);
$func = Data::Object::Array::Func::Grep->new(
  arg1 => $data,
  arg2 => sub { $_[0] > 2 }
);

my $result = $func->execute;

is_deeply $result, [3,4];

ok 1 and done_testing;
