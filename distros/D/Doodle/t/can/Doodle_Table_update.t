use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

update

=usage

  my $update = $self->update;

=description

Registers a table update and returns the Command object.

=signature

update(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Table;

can_ok "Doodle::Table", "update";

use Doodle;

my $d = Doodle->new;
my $t = $d->table('users');

my $x = $t->update(sub {
  my $t = shift;

  $t->string('fname')->create;
  $t->string('lname')->create;
  $t->string('email')->update(set => 'not null');
});

is $x->count, 3;

is $x->get(0)->name, 'create_column';
is $x->get(0)->columns->first->name, 'fname';

is $x->get(1)->name, 'create_column';
is $x->get(1)->columns->first->name, 'lname';

is $x->get(2)->name, 'update_column';
is $x->get(2)->columns->first->name, 'email';

ok 1 and done_testing;
