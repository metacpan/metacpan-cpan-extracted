use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

default

=usage

  $try = $try->default(fun ($caught) {
    # do something
  });

=description

The default method takes a method name or coderef and is triggered if no
C<catch> conditions match the exception thrown.

=signature

default(Str | CodeRef $callback) : Object

=type

method

=cut

# TESTING

use Data::Object::Try;

can_ok "Data::Object::Try", "default";

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

ok !$try->on_default;

$try->default(sub{['default', @_]});

ok $try->on_default;

is_deeply $try->on_default->(1,2,3), ['default', 1..3];

ok 1 and done_testing;
