use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Hash->new({1..8,9,undef});

  my $sets = [];

  my $func = Data::Object::Hash::Func::EachNValues->new(
    arg1 => $data,
    arg2 => 2,
    arg3 => sub { push @$sets, [@_] }
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
use Data::Object::Hash::Func::EachNValues;

can_ok "Data::Object::Hash::Func::EachNValues", "execute";

my $data;
my $func;

my $list = [];

$data = Data::Object::Hash->new({1..8,9,undef});
$func = Data::Object::Hash::Func::EachNValues->new(
  arg1 => $data,
  arg2 => 2,
  arg3 => sub { push @$list, map { $_ || 0 } @_ }
);

my $result = $func->execute;

is_deeply $result, [2,4,5];

is_deeply [sort @$list], [0,2,4,6,8];

ok 1 and done_testing;
