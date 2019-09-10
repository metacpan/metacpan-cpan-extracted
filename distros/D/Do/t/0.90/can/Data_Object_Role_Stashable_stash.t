use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

stash

=usage

  $self->stash; # {}
  $self->stash('now', time); # $time
  $self->stash('now'); # $time

=description

The stash method is used to fetch and stash named values associated with the
object. Calling this method without arguments returns all stashed data.

=signature

stash(Maybe[Str] $key, Maybe[Any] $value) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Stashable';

can_ok "Data::Object::Role::Stashable", "stash";

ok 1 and done_testing;
