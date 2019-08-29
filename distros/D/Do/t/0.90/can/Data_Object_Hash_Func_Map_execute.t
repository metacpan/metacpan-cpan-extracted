use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Hash->new({1..8,9,undef});

  my $func = Data::Object::Hash::Func::Map->new(
    arg1 => $data,
    arg2 => sub { $_[0] + 1 }
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
use Data::Object::Hash::Func::Map;

can_ok "Data::Object::Hash::Func::Map", "execute";

my $data;
my $func;

$data = Data::Object::Hash->new({1..8,9,undef});
$func = Data::Object::Hash::Func::Map->new(
  arg1 => $data,
  arg2 => sub { $_[0] + 1 }
);

my $result = $func->execute;

is_deeply [sort { $a <=> $b } @$result], [2,4,6,8,10];

ok 1 and done_testing;
