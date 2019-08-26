use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Number->new(10);

  my $func = Data::Object::Func::Number::Downto->new(
    arg1 => $data,
    arg2 => 6
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
use Data::Object::Func::Number::Downto;

can_ok "Data::Object::Func::Number::Downto", "execute";

my $data;
my $func;

$data = Data::Object::Number->new(10);
$func = Data::Object::Func::Number::Downto->new(
  arg1 => $data,
  arg2 => 5
);

my $result = $func->execute;

is_deeply $result, [10,9,8,7,6,5];

ok 1 and done_testing;
