use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

no_morphs

=usage

  my $no_morphs = $self->no_morphs('profile');

=description

Registers a drop for C<{name}_fkey> and C<{name}_type> polymorphic columns and
returns the Command object set.

=signature

no_morphs(Str $name) : [Command]

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Table::Helpers;

can_ok "Doodle::Table::Helpers", "no_morphs";

my $d = Doodle->new;
my $t = $d->table('users');
my $x = $t->no_morphs('profile');

my $type = $x->[0];
my $fkey = $x->[1];

isa_ok $type, 'Doodle::Command';
isa_ok $fkey, 'Doodle::Command';

is $type->columns->first->name, 'profile_type';
is $type->name, 'delete_column';

is $fkey->columns->first->name, 'profile_fkey';
is $fkey->name, 'delete_column';

ok 1 and done_testing;
