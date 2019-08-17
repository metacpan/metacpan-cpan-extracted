use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rename

=usage

  my $rename = $self->rename;

=description

Registers a column rename and returns the Command object.

=signature

rename(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Column;

can_ok "Doodle::Column", "rename";

ok 1 and done_testing;
