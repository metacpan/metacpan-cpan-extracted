use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Regexp->new(qr/test/);

  my $func = Data::Object::Func::Regexp::Lt->new(
    arg1 => $data,
    arg2 => ''
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
use Data::Object::Func::Regexp::Lt;

can_ok "Data::Object::Func::Regexp::Lt", "execute";

my $data;
my $func;

$data = Data::Object::Regexp->new(qr/test/);
$func = Data::Object::Func::Regexp::Lt->new(
  arg1 => $data,
  arg2 => ''
);

ok !eval { $func->execute } && $@ =~ m{ not supported };

ok 1 and done_testing;
