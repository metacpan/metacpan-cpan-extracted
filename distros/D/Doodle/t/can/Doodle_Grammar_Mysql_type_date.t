use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_date

=usage

  $self->type_date($column);

  # date

=description

Returns the type expression for a date column.

=signature

type_date(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mysql', 'type_date';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $c = $t->date('data');
my $s = $g->type_date($c);

is $s, 'date';

ok 1 and done_testing;
