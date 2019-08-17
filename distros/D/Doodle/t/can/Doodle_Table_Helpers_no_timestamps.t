use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

no_timestamps

=usage

  my $no_timestamps = $self->no_timestamps;

=description

Registers a drop for C<created_at>, C<updated_at> and C<deleted_at> columns and
returns the Command object set.

=signature

no_timestamps() : [Command]

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Table::Helpers;

can_ok "Doodle::Table::Helpers", "no_timestamps";

my $d = Doodle->new;
my $t = $d->table('users');
my $x = $t->no_timestamps;

my $created_at = $x->[0];
my $updated_at = $x->[1];
my $deleted_at = $x->[2];

isa_ok $created_at, 'Doodle::Command';
isa_ok $updated_at, 'Doodle::Command';
isa_ok $deleted_at, 'Doodle::Command';

is $created_at->columns->first->name, 'created_at';
is $created_at->name, 'delete_column';

is $updated_at->columns->first->name, 'updated_at';
is $updated_at->name, 'delete_column';

is $deleted_at->columns->first->name, 'deleted_at';
is $deleted_at->name, 'delete_column';

ok 1 and done_testing;
