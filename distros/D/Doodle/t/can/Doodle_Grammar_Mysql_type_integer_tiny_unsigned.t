use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_integer_tiny_unsigned

=usage

  $self->type_integer_tiny_unsigned($column);

  # tinyint unsigned

=description

Returns the type expression for a integer_tiny_unsigned column.

=signature

type_integer_tiny_unsigned(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mysql', 'type_integer_tiny_unsigned';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $c = $t->integer_tiny_unsigned('data');
my $s = $g->type_integer_tiny_unsigned($c);

is $s, 'tinyint unsigned';

ok 1 and done_testing;
