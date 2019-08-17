use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

table

=usage

  my $table = $self->table('users');

=description

Return a new Table object.

=signature

table(Str $name, Any %args) : Table

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle', 'table';

my $d = Doodle->new;
my $t = $d->table('users');

isa_ok $t, 'Doodle::Table';

is $t->name, 'users';

ok 1 and done_testing;
