use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rename

=usage

  my $rename = $self->rename;

=description

Registers a table rename and returns the Command object.

=signature

rename(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle;

can_ok "Doodle::Table", "rename";

my $d = Doodle->new;
my $t = $d->table('users');
my $x = $t->rename('people');

isa_ok $x, 'Doodle::Command';

is $x->name, 'rename_table';
is $x->table->data->{to}, 'people';

ok 1 and done_testing;
