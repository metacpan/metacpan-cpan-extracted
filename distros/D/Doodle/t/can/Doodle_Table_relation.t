use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

relation

=usage

  my $relation = $self->relation('profile_id', 'profiles', 'id');

=description

Returns a new Relation object.

=signature

relation(Str $column, Str $ftable, Str $fcolumn, Any %args) : Relation

=type

method

=cut

# TESTING

use Doodle;

can_ok "Doodle::Table", "relation";

my $d = Doodle->new;
my $t = $d->table('users');
my $r = $t->relation('profile_id', 'profiles', 'id');

isa_ok $r, 'Doodle::Relation';

is $r->column, 'profile_id';
is $r->foreign_table, 'profiles';
is $r->foreign_column, 'id';

ok 1 and done_testing;
