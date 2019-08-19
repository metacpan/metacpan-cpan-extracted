use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

on_delete

=usage

  my $on_delete = $self->on_delete('cascade');

=description

Denote the "ON DELETE" action for a foreign key constraint and returns the Relation.

=signature

on_delete(Str $action) : Relation

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Relation::Helpers;

can_ok 'Doodle::Relation::Helpers', 'on_delete';

my $d = Doodle->new;
my $t = $d->table('users');
my $r = $t->relation('profile_id', 'profiles');

$r->on_delete('cascade');

isa_ok $r, 'Doodle::Relation';

is $r->data->{on_delete}, 'cascade';

ok 1 and done_testing;

