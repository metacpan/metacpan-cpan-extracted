use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Regexp->new(qr/test/);

  my $func = Data::Object::Regexp::Func::Defined->new(
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

use Data::Object::Regexp;
use Data::Object::Regexp::Func::Defined;

can_ok "Data::Object::Regexp::Func::Defined", "execute";

my $data;
my $func;

$data = Data::Object::Regexp->new(qr/test/);
$func = Data::Object::Regexp::Func::Defined->new(
  arg1 => $data
);

my $result = $func->execute;

is_deeply $result, 1;

ok 1 and done_testing;
