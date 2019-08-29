use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Number->new(1);

  my $func = Data::Object::Number::Func::Exp->new(
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
use Data::Object::Number::Func::Exp;

can_ok "Data::Object::Number::Func::Exp", "execute";

my $data;
my $func;

$data = Data::Object::Number->new(1);
$func = Data::Object::Number::Func::Exp->new(
  arg1 => $data
);

my $result = $func->execute;

like $result, qr/2.71828/;

ok 1 and done_testing;
