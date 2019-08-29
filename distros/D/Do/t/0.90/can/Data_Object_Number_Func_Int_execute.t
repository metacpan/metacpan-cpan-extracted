use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Number->new(12.5);

  my $func = Data::Object::Number::Func::Int->new(
    arg1 => $data
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
use Data::Object::Number::Func::Int;

can_ok "Data::Object::Number::Func::Int", "execute";

my $data;
my $func;

$data = Data::Object::Number->new(12.5);
$func = Data::Object::Number::Func::Int->new(
  arg1 => $data
);

my $result = $func->execute;

is_deeply $result, 12;

ok 1 and done_testing;
