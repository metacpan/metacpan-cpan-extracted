use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

index

=usage

  my $index = $self->index(columns => ['email', 'password']);

=description

Returns a new Index object.

=signature

index(ArrayRef :$columns, Any %args) : Index

=type

method

=cut

# TESTING

use Doodle;

can_ok "Doodle::Table", "index";

my $d = Doodle->new;
my $t = $d->table('users');
my $i = $t->index(columns => ['profile_id']);

isa_ok $i, 'Doodle::Index';

is_deeply $i->columns, ['profile_id'];

ok 1 and done_testing;
