use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_timestamp_tz

=usage

  $self->type_timestamp_tz($column);

  # timestamp(0) with time zone

=description

Returns the type expression for a timestamp_tz column.

=signature

type_timestamp_tz(Column $column) :

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Postgres', 'type_timestamp_tz';

my $d = Doodle->new;
my $g = Doodle::Grammar::Postgres->new;
my $t = $d->table('users');
my $c = $t->timestamp_tz('data');
my $s = $g->type_timestamp_tz($c);

is $s, 'timestamp(0) with time zone';

ok 1 and done_testing;
