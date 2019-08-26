use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Number->new(5);

  my $func = Data::Object::Func::Number::To->new(
    arg1 => $data,
    arg2 => 8
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
use Data::Object::Func::Number::To;

can_ok "Data::Object::Func::Number::To", "execute";

my $data;
my $func;

$data = Data::Object::Number->new(5);
$func = Data::Object::Func::Number::To->new(
  arg1 => $data,
  arg2 => 9
);

my $result = $func->execute;

is_deeply $result, [5,6,7,8,9];

ok 1 and done_testing;
