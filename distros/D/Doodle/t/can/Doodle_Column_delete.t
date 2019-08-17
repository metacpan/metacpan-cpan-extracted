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

Registers a column delete and returns the Command object.

=signature

delete(Any %args) : Column

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Column;

can_ok "Doodle::Column", "delete";

my $d = Doodle->new;
my $t = $d->table('users');
my $c = $t->column('email');
my $x = $c->delete;

isa_ok $c, 'Doodle::Column';
isa_ok $x, 'Doodle::Command';

is $c->type, 'string';
is $c, $x->columns->first;
is $x->name, 'delete_column';

ok 1 and done_testing;
