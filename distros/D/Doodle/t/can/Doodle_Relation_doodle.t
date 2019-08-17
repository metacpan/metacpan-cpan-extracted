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

doodle(Any %args) : Doodle

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Relation', 'doodle';

my $d = Doodle->new;
my $t = $d->table('users');
my $r = $t->relation('profile_id', 'profiles', 'id');

isa_ok $r->doodle, 'Doodle';

is $r->doodle, $d;

ok 1 and done_testing;
