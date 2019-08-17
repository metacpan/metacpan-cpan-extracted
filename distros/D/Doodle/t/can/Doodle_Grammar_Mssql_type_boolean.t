use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_boolean

=usage

  $self->type_boolean($column);

  # bit

=description

Returns the type expression for a boolean column.

=signature

type_boolean(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mssql', 'type_boolean';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mssql->new;
my $t = $d->table('users');
my $c = $t->boolean('data');
my $s = $g->type_boolean($c);

is $s, 'bit';

ok 1 and done_testing;
