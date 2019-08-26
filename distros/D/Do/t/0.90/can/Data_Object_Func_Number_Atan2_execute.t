use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Number->new(1);

  my $func = Data::Object::Func::Number::Atan2->new(
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

use Data::Object::Number;
use Data::Object::Func::Number::Atan2;

can_ok "Data::Object::Func::Number::Atan2", "execute";

my $data;
my $func;

$data = Data::Object::Number->new(1);
$func = Data::Object::Func::Number::Atan2->new(
  arg1 => $data,
  arg2 => 1
);

my $result = $func->execute;

like $result, qr/0.78539/;

ok 1 and done_testing;
