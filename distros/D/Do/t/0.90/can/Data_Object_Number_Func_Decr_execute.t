use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Number->new(100);

  my $func = Data::Object::Number::Func::Decr->new(
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
use Data::Object::Number::Func::Decr;

can_ok "Data::Object::Number::Func::Decr", "execute";

my $data;
my $func;

$data = Data::Object::Number->new(100);
$func = Data::Object::Number::Func::Decr->new(
  arg1 => $data
);

my $result = $func->execute;

is_deeply $result, 99;

ok 1 and done_testing;
