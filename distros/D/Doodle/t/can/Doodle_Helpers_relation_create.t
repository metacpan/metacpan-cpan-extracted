use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

relation_create

=usage

  my $command = $self->relation_create(%args);

=description

Registers a relation create and returns the Command object.

=signature

relation_create(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Helpers;

use_ok 'Doodle::Helpers', 'relation_create';

ok 1 and done_testing;
