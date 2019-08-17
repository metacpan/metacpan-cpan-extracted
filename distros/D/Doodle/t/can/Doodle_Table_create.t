use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

create

=usage

  my $create = $self->create;

=description

Registers a table create and returns the Command object.

=signature

create(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle;

can_ok "Doodle::Table", "create";

my $d = Doodle->new;
my $t = $d->table('users');

$t->primary('id');
$t->string('fname');
$t->string('lname');
$t->string('email');
$t->create;

my $x = $d->commands;

is $x->count, 1;

is $x->get(0)->name, 'create_table';
is $x->get(0)->table, $t;
is $x->get(0)->columns->count, 4;
is $x->get(0)->indices->count, 0;
is $x->get(0)->relation, undef;

ok 1 and done_testing;
