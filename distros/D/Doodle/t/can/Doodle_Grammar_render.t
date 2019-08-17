use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

render

=usage

  my $sql = $self->render($command);

=description

Returns the SQL statement for the given Command.

=signature

render(Command $command) : Str

=type

method

=cut

# TESTING

use_ok 'Doodle::Grammar', 'render';

ok 1 and done_testing;
