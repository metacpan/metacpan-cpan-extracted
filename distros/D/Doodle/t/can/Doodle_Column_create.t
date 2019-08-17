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

Registers a column create and returns the Command object.

=signature

create(Any %args) : Column

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Column;

can_ok "Doodle::Column", "create";

my $d = Doodle->new;
my $t = $d->table('users');
my $c = $t->column('email');
my $x = $c->create;

isa_ok $c, 'Doodle::Column';
isa_ok $x, 'Doodle::Command';

is $c->type, 'string';
is $c, $x->columns->first;
is $x->name, 'create_column';

ok 1 and done_testing;
