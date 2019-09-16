use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

call

=usage

  $try = $try->call($method);
  $try = $try->call(fun (@args) {
    # do something
  });

=description

The call method takes a method name or coderef, registers it as the tryable
routine, and returns the object. When invoked, the callback will received an
C<invocant> if one was provided to the constructor, the default C<arguments> if
any were provided to the constructor, and whatever arguments were provided by
the invocant.

=signature

call(Str | CodeRef $method) : Object

=type

method

=cut

# TESTING

use Data::Object::Try;

can_ok "Data::Object::Try", "call";

my $try;

$try = Data::Object::Try->new;

ok !$try->on_try;
isa_ok $try->call(sub{['tried', @_]}), 'Data::Object::Try';
isa_ok $try->on_try, 'CODE';
is_deeply $try->on_try->(1,2,3), ['tried', 1..3];

ok 1 and done_testing;
