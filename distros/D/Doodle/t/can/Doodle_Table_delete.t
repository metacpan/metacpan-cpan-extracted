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

Registers a table delete and returns the Command object.

=signature

delete(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle;

can_ok "Doodle::Table", "delete";

my $d = Doodle->new;
my $t = $d->table('users');

$t->delete;

my $x = $d->commands;

is $x->count, 1;

is $x->get(0)->name, 'delete_table';
is $x->get(0)->table, $t;
is $x->get(0)->columns, undef;
is $x->get(0)->indices, undef;
is $x->get(0)->relation, undef;

ok 1 and done_testing;
