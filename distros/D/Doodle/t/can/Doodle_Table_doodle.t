use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

doodle

=usage

  my $doodle = $self->doodle;

=description

Returns the associated Doodle object.

=signature

doodle() : Doodle

=type

method

=cut

# TESTING

use Doodle;

can_ok "Doodle::Table", "doodle";

my $d = Doodle->new;
my $t = $d->table('users');

is $t->doodle, $d;

ok 1 and done_testing;
