use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_datetime

=usage

  $self->type_datetime($column);

  # timestamp(0) without time zone

=description

Returns the type expression for a datetime column.

=signature

type_datetime(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Postgres', 'type_datetime';

my $d = Doodle->new;
my $g = Doodle::Grammar::Postgres->new;
my $t = $d->table('users');
my $c = $t->datetime('data');
my $s = $g->type_datetime($c);

is $s, 'timestamp(0) without time zone';

ok 1 and done_testing;
