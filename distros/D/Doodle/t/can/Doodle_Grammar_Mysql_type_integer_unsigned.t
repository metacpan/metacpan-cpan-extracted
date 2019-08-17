use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_integer_unsigned

=usage

  $self->type_integer_unsigned($column);

  # int unsigned

=description

Returns the type expression for a integer_unsigned column.

=signature

type_integer_unsigned(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mysql', 'type_integer_unsigned';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $c = $t->integer_unsigned('data');
my $s = $g->type_integer_unsigned($c);

is $s, 'int unsigned';

ok 1 and done_testing;
