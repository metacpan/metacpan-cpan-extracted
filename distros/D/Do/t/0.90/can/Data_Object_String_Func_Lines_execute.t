use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::String->new("hello\nworld");

  my $func = Data::Object::String::Func::Lines->new(
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

use Data::Object::String;
use Data::Object::String::Func::Lines;

can_ok "Data::Object::String::Func::Lines", "execute";

my $data;
my $func;

$data = Data::Object::String->new("hello\nworld");
$func = Data::Object::String::Func::Lines->new(
  arg1 => $data
);

my $result = $func->execute;

is_deeply $result, ["hello", "world"];

ok 1 and done_testing;
