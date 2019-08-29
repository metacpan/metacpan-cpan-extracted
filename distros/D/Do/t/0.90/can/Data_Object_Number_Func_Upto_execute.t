use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Number->new(23);

  my $func = Data::Object::Number::Func::Upto->new(
    arg1 => $data,
    arg2 => 14
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

use Data::Object::Number;
use Data::Object::Number::Func::Upto;

can_ok "Data::Object::Number::Func::Upto", "execute";

my $data;
my $func;

$data = Data::Object::Number->new(23);
$func = Data::Object::Number::Func::Upto->new(
  arg1 => $data,
  arg2 => 25
);

my $result = $func->execute;

is_deeply $result, [23,24,25];

ok 1 and done_testing;
