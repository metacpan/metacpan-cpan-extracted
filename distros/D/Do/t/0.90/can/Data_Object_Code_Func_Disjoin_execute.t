use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Code->new(sub { $_[0] % 2 });

  my $func = Data::Object::Code::Func::Disjoin->new(
    arg1 => $data,
    arg2 => sub { -1 }
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

use Data::Object::Code;
use Data::Object::Code::Func::Disjoin;

can_ok "Data::Object::Code::Func::Disjoin", "execute";

my $data;
my $func;

$data = Data::Object::Code->new(sub { $_[0] % 2 });
$func = Data::Object::Code::Func::Disjoin->new(
  arg1 => $data,
  arg2 => sub { -1 }
);

my $result = $func->execute;

is ref($result), 'CODE';

is_deeply $result->(0), -1;
is_deeply $result->(1), 1;
is_deeply $result->(2), -1;
is_deeply $result->(3), 1;
is_deeply $result->(4), -1;

ok 1 and done_testing;
