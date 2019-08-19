use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

on_update

=usage

  my $on_update = $self->on_update('cascade');

=description

Denote the "ON UPDATE" action for a foreign key constraint and returns the Relation.

=signature

on_update(Str $action) : Relation

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Relation::Helpers;

can_ok 'Doodle::Relation::Helpers', 'on_update';

my $d = Doodle->new;
my $t = $d->table('users');
my $r = $t->relation('profile_id', 'profiles');

$r->on_update('cascade');

isa_ok $r, 'Doodle::Relation';

is $r->data->{on_update}, 'cascade';

ok 1 and done_testing;
