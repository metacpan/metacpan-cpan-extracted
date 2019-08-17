use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $statement = $self->execute($command);

=description

Processed the Command and returns a Statement object.

=signature

execute(Command $command) : Statement

=type

method

=cut

# TESTING

use_ok 'Doodle::Grammar', 'execute';

ok 1 and done_testing;
