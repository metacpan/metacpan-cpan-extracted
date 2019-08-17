use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete

=usage

  my $delete = $self->delete;

=description

Registers a relation update and returns the Command object.

=signature

delete(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Relation', 'delete';

my $d = Doodle->new;
my $t = $d->table('users');
my $x = $t->delete;

isa_ok $x, 'Doodle::Command';

is $x->name, 'delete_table';

ok 1 and done_testing;
