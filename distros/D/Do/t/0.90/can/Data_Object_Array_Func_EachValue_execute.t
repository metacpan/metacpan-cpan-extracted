use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Array->new([1..4]);

  my $sets = [];

  my $func = Data::Object::Array::Func::EachValue->new(
    arg1 => $data,
    arg2 => sub { push @$sets, [@_] }
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

use Data::Object::Array;
use Data::Object::Array::Func::EachValue;

can_ok "Data::Object::Array::Func::EachValue", "execute";

my $data;
my $func;

my $sets = [];

$data = Data::Object::Array->new([1..4]);
$func = Data::Object::Array::Func::EachValue->new(
  arg1 => $data,
  arg2 => sub { push @$sets, [@_] }
);

my $result = $func->execute;

is_deeply $result, $data;

is_deeply $sets, [[1],[2],[3],[4]];

ok 1 and done_testing;
