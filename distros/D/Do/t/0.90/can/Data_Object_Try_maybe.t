use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

maybe

=usage

  $try = $try->maybe;

=description

The maybe method registers a default C<catch> condition that returns an falsy,
i.e. an empty string, if an exception is encountered.

=signature

maybe() : Object

=type

method

=cut

# TESTING

use Data::Object::Try;

can_ok "Data::Object::Try", "maybe";

{
  package Event;

  use Moo;

  extends 'Data::Object::Try';

  sub request {
    die ['oops'];
  }

  1;
}

my $try;
my $callback;

$try = Event->new;
$try->call('request');

ok !$try->on_default;

$try->maybe;

ok $try->on_default;

is $try->on_default->(), '';
is $try->result, '';

ok 1 and done_testing;
