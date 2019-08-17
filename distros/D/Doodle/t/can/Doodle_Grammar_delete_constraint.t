use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete_constraint

=usage

  $self->delete_constraint($column);

  # 

=description

Returns the SQL statement for the delete constraint command.

=signature

delete_constraint(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar', 'delete_constraint';

ok 1 and done_testing;
