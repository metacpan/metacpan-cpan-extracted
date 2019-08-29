use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Hash->new({3,[4,5,6],7,{8,8,9,9}});

  my $func = Data::Object::Hash::Func::Fold->new(
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

use Data::Object::Hash;
use Data::Object::Hash::Func::Fold;

can_ok "Data::Object::Hash::Func::Fold", "execute";

my $data;
my $func;

$data = Data::Object::Hash->new({3,[4,5,6],7,{8,8,9,9}});
$func = Data::Object::Hash::Func::Fold->new(
  arg1 => $data
);

my $result = $func->execute;

is_deeply $result, {
  '3:0'=>4,
  '3:1'=>5,
  '3:2'=>6,
  '7.8'=>8,
  '7.9'=>9
};

ok 1 and done_testing;
