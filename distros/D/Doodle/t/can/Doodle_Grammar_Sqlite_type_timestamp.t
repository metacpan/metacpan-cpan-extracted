use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_timestamp

=usage

  $self->type_timestamp($column);

  # datetime

=description

Returns the type expression for a timestamp column.

=signature

type_timestamp(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Sqlite', 'type_timestamp';

my $d = Doodle->new;
my $g = Doodle::Grammar::Sqlite->new;
my $t = $d->table('users');
my $c = $t->timestamp('data');
my $s = $g->type_timestamp($c);

is $s, 'datetime';

ok 1 and done_testing;
