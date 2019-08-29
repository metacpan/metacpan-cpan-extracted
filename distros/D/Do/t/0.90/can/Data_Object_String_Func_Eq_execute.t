use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::String->new("hello");

  my $func = Data::Object::String::Func::Eq->new(
    arg1 => $data,
    arg2 => 'hello'
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

use Data::Object::String;
use Data::Object::String::Func::Eq;

can_ok "Data::Object::String::Func::Eq", "execute";

my $data;
my $func;

$data = Data::Object::String->new("hello");
$func = Data::Object::String::Func::Eq->new(
  arg1 => $data,
  arg2 => 'hello'
);

my $result = $func->execute;

is_deeply $result, 1;

ok 1 and done_testing;
