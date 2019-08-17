use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_time_tz

=usage

  $self->type_time_tz($column);

  # time(0) with time zone

=description

Returns the type expression for a time_tz column.

=signature

type_time_tz(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Postgres', 'type_time_tz';

my $d = Doodle->new;
my $g = Doodle::Grammar::Postgres->new;
my $t = $d->table('users');
my $c = $t->time_tz('data');
my $s = $g->type_time_tz($c);

is $s, 'time(0) with time zone';

ok 1 and done_testing;
