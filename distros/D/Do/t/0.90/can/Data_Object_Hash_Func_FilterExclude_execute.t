use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Hash->new({1..8});

  my $func = Data::Object::Hash::Func::FilterExclude->new(
    arg1 => $data,
    args => [1,3]
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
use Data::Object::Hash::Func::FilterExclude;

can_ok "Data::Object::Hash::Func::FilterExclude", "execute";

my $data;
my $func;

$data = Data::Object::Hash->new({1..8});
$func = Data::Object::Hash::Func::FilterExclude->new(
  arg1 => $data,
  args => [1,3]
);

my $result = $func->execute;

is_deeply $result, {5=>6,7=>8};

ok 1 and done_testing;
