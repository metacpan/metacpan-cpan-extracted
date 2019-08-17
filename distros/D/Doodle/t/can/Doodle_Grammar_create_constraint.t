use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

create_constraint

=usage

  $self->create_constraint($column);

  # 

=description

Returns the SQL statement for the create constraint command.

=signature

create_constraint(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar', 'create_constraint';

ok 1 and done_testing;
