use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_json

=usage

  $self->type_json($column);

  # nvarchar(max)

=description

Returns the type expression for a json column.

=signature

type_json(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mssql', 'type_json';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mssql->new;
my $t = $d->table('users');
my $c = $t->json('data');
my $s = $g->type_json($c);

is $s, 'nvarchar(max)';

ok 1 and done_testing;
