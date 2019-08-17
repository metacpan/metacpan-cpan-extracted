use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_integer_big_unsigned

=usage

  $self->type_integer_big_unsigned($column);

  # bigint

=description

Returns the type expression for a integer_big_unsigned column.

=signature

type_integer_big_unsigned(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Postgres', 'type_integer_big_unsigned';

my $d = Doodle->new;
my $g = Doodle::Grammar::Postgres->new;
my $t = $d->table('users');
my $c = $t->integer_big_unsigned('data');
my $s = $g->type_integer_big_unsigned($c);

is $s, 'bigint';

ok 1 and done_testing;
