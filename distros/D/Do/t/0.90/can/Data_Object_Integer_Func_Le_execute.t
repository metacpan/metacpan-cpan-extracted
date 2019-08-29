use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Integer->new(1);

  my $func = Data::Object::Integer::Func::Le->new(
    arg1 => $data,
    arg2 => 1
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

use Data::Object::Integer;
use Data::Object::Integer::Func::Le;

can_ok "Data::Object::Integer::Func::Le", "execute";

my $data;
my $func;

$data = Data::Object::Integer->new(1);
$func = Data::Object::Integer::Func::Le->new(
  arg1 => $data,
  arg2 => 1
);

my $result = $func->execute;

is_deeply $result, 1;

ok 1 and done_testing;
