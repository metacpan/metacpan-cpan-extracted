use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

index_create

=usage

  my $command = $self->index_create(%args);

=description

Registers a index create and returns the Command object.

=signature

index_create(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Helpers;

can_ok "Doodle::Helpers", "index_create";

ok 1 and done_testing;
