use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Hash->new({1..8});

  my $func = Data::Object::Hash::Func::Ge->new(
    arg1 => $data,
    arg2 => {1..4}
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
use Data::Object::Hash::Func::Ge;

can_ok "Data::Object::Hash::Func::Ge", "execute";

my $data;
my $func;

$data = Data::Object::Hash->new({1..8});
$func = Data::Object::Hash::Func::Ge->new(
  arg1 => $data,
  arg2 => {1..4}
);

ok !eval { $func->execute } && $@ =~ m{ not supported };

ok 1 and done_testing;
