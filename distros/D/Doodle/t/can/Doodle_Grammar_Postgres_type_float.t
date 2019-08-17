use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_float

=usage

  $self->type_float($column);

  # double precision

=description

Returns the type expression for a float column.

=signature

type_float(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Postgres', 'type_float';

my $d = Doodle->new;
my $g = Doodle::Grammar::Postgres->new;
my $t = $d->table('users');
my $c = $t->float('data');
my $s = $g->type_float($c);

is $s, 'double precision';

ok 1 and done_testing;
