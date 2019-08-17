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
use Doodle::Column;

can_ok "Doodle::Column", "doodle";

my $d = Doodle->new;
my $t = $d->table('users');
my $z = $t->column('avatar')->doodle;

isa_ok $z, 'Doodle';

is $d, $z;

ok 1 and done_testing;
