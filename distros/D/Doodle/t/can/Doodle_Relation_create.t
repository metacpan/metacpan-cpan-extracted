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

Registers a relation create and returns the Command object.

=signature

create(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Relation', 'create';

my $d = Doodle->new;
my $t = $d->table('users');
my $r = $t->relation('profile_id', 'profiles', 'id');
my $x = $r->create;

isa_ok $r, 'Doodle::Relation';
isa_ok $x, 'Doodle::Command';

is $x->name, 'create_relation';
is $x->relation->name, 'fkey_users_profile_id_profiles_id';
is $x->relation->column, 'profile_id';
is $x->relation->foreign_table, 'profiles';
is $x->relation->foreign_column, 'id';

ok 1 and done_testing;
