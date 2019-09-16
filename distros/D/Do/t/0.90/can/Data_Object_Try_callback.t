use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

callback

=usage

  my $callback;

  $callback = $try->callback($method);
  $callback = $try->callback(fun (@args) {
    # do something
  });

=description

The callback method takes a method name or coderef, and returns a coderef for
registration. If a coderef is provided this method is mostly a passthrough.

=signature

callback(Str | CodeRef) : CodeRef

=type

method

=cut

# TESTING

use Data::Object::Try;

can_ok "Data::Object::Try", "callback";

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

$try = Data::Object::Try->new;
$callback = $try->callback(sub{['tried', @_]});

isa_ok $callback, 'CODE';
is_deeply $callback->(1,2,3), ['tried', 1..3];

$try = Event->new;
$callback = $try->callback('failure');

isa_ok $callback, 'CODE';
is_deeply $callback->(1,2,3), ['logged', 1..3];

ok 1 and done_testing;
