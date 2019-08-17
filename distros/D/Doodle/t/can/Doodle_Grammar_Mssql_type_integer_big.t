use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_integer_big

=usage

  $self->type_integer_big($column);

  # bigint

=description

Returns the type expression for a integer_big column.

=signature

type_integer_big(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mssql', 'type_integer_big';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mssql->new;
my $t = $d->table('users');
my $c = $t->integer_big('data');
my $s = $g->type_integer_big($c);

is $s, 'bigint';

ok 1 and done_testing;
