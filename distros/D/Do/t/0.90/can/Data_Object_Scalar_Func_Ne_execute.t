use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Scalar->new(\*main);

  my $func = Data::Object::Scalar::Func::Ne->new(
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

no warnings 'once';

use Data::Object::Scalar;
use Data::Object::Scalar::Func::Ne;

can_ok "Data::Object::Scalar::Func::Ne", "execute";

my $data;
my $func;

$data = Data::Object::Scalar->new(\*main);
$func = Data::Object::Scalar::Func::Ne->new(
  arg1 => $data,
  arg2 => undef
);

ok !eval { $func->execute } && $@ =~ m{ not supported };

ok 1 and done_testing;
