use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

catch

=usage

  $try = $try->catch('Error::HTTP400', fun ($caught) {
    # do something
  });

  $try = $try->catch('Error::HTTP401', fun ($caught) {
    # do something
  });

=description

The catch method takes a package or ref name, and when triggered checks whether
the captured exception is of the type specified and if so executes the given
callback.

=signature

catch(Str $isa, Str | CodeRef $callback) : Any

=type

method

=cut

# TESTING

use Data::Object::Try;

can_ok "Data::Object::Try", "catch";

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

ok $try->on_catch;
ok !@{$try->on_catch};

$try->catch('ARRAY', sub{['caught', @_]});

ok $try->on_catch;
ok @{$try->on_catch};

is $try->on_catch->[0][0], 'ARRAY';
is_deeply $try->on_catch->[0][1]->(1,2,3), ['caught', 1..3];

ok 1 and done_testing;
