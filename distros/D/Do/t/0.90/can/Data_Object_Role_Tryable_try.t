use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

try

=usage

  my $try;

  $try = $self->try($method);
  $try = $self->try(fun ($self) {
    # do something

    return $something;
  });

=description

The try method takes a method name or coderef and returns a
L<Data::Object::Try> object with the current object passed as the invocant
which means that C<try> and C<finally> callbacks will receive that as the first
argument.

=signature

try(Str | CodeRef $method) : Object

=type

method

=cut

# TESTING

use Data::Object::Role::Tryable;

can_ok "Data::Object::Role::Tryable", "try";

{
  package Event;

  use Moo;

  with 'Data::Object::Role::Tryable';

  sub request {
    die ['Oops'];
  }

  sub failure {
    return ['Log', @_];
  }

  1;
}

my $event = Event->new;
my $try = $event->try('request');
$try->default('failure');

isa_ok $try, 'Data::Object::Try';
is_deeply $try->result('Yay'), ['Log', ['Oops']];

ok 1 and done_testing;
