use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Try

=abstract

Data-Object Try/Catch Class

=synopsis

  use Data::Object::Try;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {
    # try something

    return something
  });

  $try->catch($type, fun ($caught) {
    # caught an exception

    return $something;
  });

  $try->default(fun ($caught) {
    # catch the uncaught

    return $something;
  });

  $try->finally(fun (@args) {
    # always run after try/catch
  });

  my $result = $try->result(@args);

=library

Data::Object::Library

=attributes

invocant(Object, opt, ro)
arguments(ArrayRef, opt, ro)
on_try(CodeRef, opt, rw)
on_catch(ArrayRef[CodeRef], opt, rw)
on_default(CodeRef, opt, rw)
on_finally(CodeRef, opt, rw)

=description

This package provides an object-oriented interface for performing complex
try/catch operations.

=cut

use_ok "Data::Object::Try";

ok 1 and done_testing;
