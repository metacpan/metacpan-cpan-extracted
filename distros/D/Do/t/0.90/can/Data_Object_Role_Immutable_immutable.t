use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

immutable

=usage

  my $immutable = $self->immutable;

=description

The immutable method returns the invocant but will throw an error if an attempt
is made to modify the underlying value.

=signature

immutable() : Object

=type

method

=cut

# TESTING

use Data::Object::Role::Immutable;

can_ok "Data::Object::Role::Immutable", "immutable";

{
  package User;

  use Data::Object::Class;

  with 'Data::Object::Role::Immutable';

  sub BUILD {
    my ($self, $args) = @_;

    $self->immutable;

    return $args;
  }

  1;
}

my $user = User->new;
my $error = qr/modification of a read-only value/i;

isa_ok $user, 'User';

ok !eval { $user->{time} = time };
ok $@ =~ qr/$error/;

ok 1 and done_testing;
