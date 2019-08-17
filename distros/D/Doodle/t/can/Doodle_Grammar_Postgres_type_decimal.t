use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_decimal

=usage

  $self->type_decimal($column);

  # decimal(5, 2)

=description

Returns the type expression for a decimal column.

=signature

type_decimal(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Postgres', 'type_decimal';

my $d = Doodle->new;
my $g = Doodle::Grammar::Postgres->new;
my $t = $d->table('users');
my $c = $t->decimal('data');
my $s = $g->type_decimal($c);

is $s, 'decimal(5, 2)';

ok 1 and done_testing;
