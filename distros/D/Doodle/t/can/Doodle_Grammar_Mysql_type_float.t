use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_float

=usage

  $self->type_float($column);

  # double(5, 2)

=description

Returns the type expression for a float column.

=signature

type_float(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mysql', 'type_float';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $c = $t->float('data');
my $s = $g->type_float($c);

is $s, 'double(5, 2)';

ok 1 and done_testing;
