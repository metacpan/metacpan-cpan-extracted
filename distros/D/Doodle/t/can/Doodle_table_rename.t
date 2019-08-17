use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

table_rename

=usage

  my $command = $self->table_rename(%args);

=description

Registers a table rename and returns the Command object.

=signature

table_rename(Any %args) : Command

=type

method

=cut

# TESTING

use_ok 'Doodle', 'table_rename';

ok 1 and done_testing;
