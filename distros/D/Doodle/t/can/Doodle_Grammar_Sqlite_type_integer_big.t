use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_integer_big

=usage

  $self->type_integer_big($column);

  # integer

=description

Returns the type expression for a integer_big column.

=signature

type_integer_big(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Sqlite', 'type_integer_big';

my $d = Doodle->new;
my $g = Doodle::Grammar::Sqlite->new;
my $t = $d->table('users');
my $c = $t->integer_big('data');
my $s = $g->type_integer_big($c);

is $s, 'integer';

ok 1 and done_testing;
