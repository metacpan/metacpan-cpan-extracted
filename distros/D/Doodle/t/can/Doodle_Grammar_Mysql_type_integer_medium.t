use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_integer_medium

=usage

  $self->type_integer_medium($column);

  # mediumint

=description

Returns the type expression for a integer_medium column.

=signature

type_integer_medium(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mysql', 'type_integer_medium';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $c = $t->integer_medium('data');
my $s = $g->type_integer_medium($c);

is $s, 'mediumint';

ok 1 and done_testing;
