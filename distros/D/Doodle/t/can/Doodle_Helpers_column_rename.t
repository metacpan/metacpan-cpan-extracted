use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

column_rename

=usage

  my $command = $self->column_rename(%args);

=description

Registers a column rename and returns the Command object.

=signature

column_rename(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Helpers;

use_ok 'Doodle::Helpers', 'column_rename';

ok 1 and done_testing;
