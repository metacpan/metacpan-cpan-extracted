use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::String->new("hello");

  my $func = Data::Object::String::Func::Append->new(
    arg1 => $data,
    args => ['world']
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
use Data::Object::String::Func::Append;

can_ok "Data::Object::String::Func::Append", "execute";

my $data;
my $func;

$data = Data::Object::String->new("hello");
$func = Data::Object::String::Func::Append->new(
  arg1 => $data,
  args => ['world']
);

my $result = $func->execute;

is_deeply $result, 'hello world';

ok 1 and done_testing;
