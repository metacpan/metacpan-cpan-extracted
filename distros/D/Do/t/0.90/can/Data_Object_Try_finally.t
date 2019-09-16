use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

finally

=usage

  $try = $try->finally(fun (@args) {
    # always do something
  });

=description

The finally method takes a package or ref name and always executes the callback
after a try/catch operation. The return value is ignored. When invoked, the
callback will received an C<invocant> if one was provided to the constructor,
the default C<arguments> if any were provided to the constructor, and whatever
arguments were provided by the invocant.

=signature

finally(Str | CodeRef $callback) : Object

=type

method

=cut

# TESTING

use Data::Object::Try;

can_ok "Data::Object::Try", "finally";

{
  package Event;

  use Moo;

  extends 'Data::Object::Try';

  sub request {
    die ['oops'];
  }

  sub failure {
    return ['logged', @_];
  }

  1;
}

my $try;
my $callback;

$try = Event->new;
$callback = $try->callback('request');

ok !$try->on_finally;

$try->finally(sub{['always', @_]});

ok $try->on_finally;

is_deeply $try->on_finally->(1,2,3), ['always', 1..3];

ok 1 and done_testing;
