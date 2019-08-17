use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_timestamp_tz

=usage

  $self->type_timestamp_tz($column);

  # datetime

=description

Returns the type expression for a timestamp_tz column.

=signature

type_timestamp_tz(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Sqlite', 'type_timestamp_tz';

my $d = Doodle->new;
my $g = Doodle::Grammar::Sqlite->new;
my $t = $d->table('users');
my $c = $t->timestamp_tz('data');
my $s = $g->type_timestamp_tz($c);

is $s, 'datetime';

ok 1 and done_testing;
