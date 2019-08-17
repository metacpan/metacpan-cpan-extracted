use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_datetime

=usage

  $self->type_datetime($column);

  # datetime

=description

Returns the type expression for a datetime column.

=signature

type_datetime(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mysql', 'type_datetime';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $c = $t->datetime('data');
my $s = $g->type_datetime($c);

is $s, 'datetime';

ok 1 and done_testing;
