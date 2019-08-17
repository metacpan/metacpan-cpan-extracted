use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

exception

=usage

  $self->exception($message);

=description

Throws an exception using L<Carp> confess.

=signature

exception(Str $message) : ()

=type

method

=cut

# TESTING

use_ok 'Doodle::Grammar', 'exception';

ok 1 and done_testing;
