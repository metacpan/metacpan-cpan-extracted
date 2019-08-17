use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_boolean

=usage

  $self->type_boolean($column);

  # tinyint(1)

=description

Returns the type expression for a boolean column.

=signature

type_boolean(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Sqlite', 'type_boolean';

my $d = Doodle->new;
my $g = Doodle::Grammar::Sqlite->new;
my $t = $d->table('users');
my $c = $t->boolean('data');
my $s = $g->type_boolean($c);

is $s, 'tinyint(1)';

ok 1 and done_testing;
