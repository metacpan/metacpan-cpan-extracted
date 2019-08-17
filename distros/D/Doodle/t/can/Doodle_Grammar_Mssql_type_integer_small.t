use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_integer_small

=usage

  $self->type_integer_small($column);

  # smallint

=description

Returns the type expression for a integer_small column.

=signature

type_integer_small(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mssql', 'type_integer_small';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mssql->new;
my $t = $d->table('users');
my $c = $t->integer_small('data');
my $s = $g->type_integer_small($c);

is $s, 'smallint';

ok 1 and done_testing;
