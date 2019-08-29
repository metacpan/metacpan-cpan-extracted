use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Undef->new(undef);

  my $func = Data::Object::Undef::Func::Le->new(
    arg1 => $data,
    arg2 => undef
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

use Data::Object::Undef;
use Data::Object::Undef::Func::Le;

can_ok "Data::Object::Undef::Func::Le", "execute";

my $data;
my $func;

$data = Data::Object::Undef->new(undef);
$func = Data::Object::Undef::Func::Le->new(
  arg1 => $data,
  arg2 => undef
);

my $result = $func->execute;

is_deeply $result, 1;

ok 1 and done_testing;
