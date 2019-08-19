use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

relation_delete

=usage

  my $command = $self->relation_delete(%args);

=description

Registers a relation delete and returns the Command object.

=signature

relation_delete(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Helpers;

use_ok 'Doodle::Helpers', 'relation_delete';

ok 1 and done_testing;
