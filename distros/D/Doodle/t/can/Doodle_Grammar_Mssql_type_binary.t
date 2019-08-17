use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_binary

=usage

  $self->type_binary($column);

  # varbinary(max)

=description

Returns the type expression for a binary column.

=signature

type_binary(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mssql', 'type_binary';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mssql->new;
my $t = $d->table('users');
my $c = $t->binary('data');
my $s = $g->type_binary($c);

is $s, 'varbinary(max)';

ok 1 and done_testing;
