use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_integer

=usage

  $self->type_integer($column);

  # integer

=description

Returns the type expression for a integer column.

=signature

type_integer(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Sqlite', 'type_integer';

my $d = Doodle->new;
my $g = Doodle::Grammar::Sqlite->new;
my $t = $d->table('users');
my $c = $t->integer('data');
my $s = $g->type_integer($c);

is $s, 'integer';

ok 1 and done_testing;
