use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_time

=usage

  $self->type_time($column);

  # time(0) without time zone

=description

Returns the type expression for a time column.

=signature

type_time(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Postgres', 'type_time';

my $d = Doodle->new;
my $g = Doodle::Grammar::Postgres->new;
my $t = $d->table('users');
my $c = $t->time('data');
my $s = $g->type_time($c);

is $s, 'time(0) without time zone';

ok 1 and done_testing;
