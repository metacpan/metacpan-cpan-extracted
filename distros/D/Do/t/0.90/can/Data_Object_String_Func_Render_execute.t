use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::String->new("Hi, {name}!");

  my $func = Data::Object::String::Func::Render->new(
    arg1 => $data,
    arg2 => { name => 'Friends' }
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

use Data::Object::String::Func::Render;

can_ok "Data::Object::String::Func::Render", "execute";

ok 1 and done_testing;
