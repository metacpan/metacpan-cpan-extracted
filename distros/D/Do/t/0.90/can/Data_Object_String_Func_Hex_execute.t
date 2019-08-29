use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::String->new("0xaf");

  my $func = Data::Object::String::Func::Hex->new(
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
use Data::Object::String::Func::Hex;

can_ok "Data::Object::String::Func::Hex", "execute";

my $data;
my $func;

$data = Data::Object::String->new("0xaf");
$func = Data::Object::String::Func::Hex->new(
  arg1 => $data
);

my $result = $func->execute;

is_deeply $result, 175;

ok 1 and done_testing;
