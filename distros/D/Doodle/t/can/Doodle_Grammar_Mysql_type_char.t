use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_char

=usage

  $self->type_char($column);

  # char(1)

  $self->type_char($column, size => 10);

  # char(10)

=description

Returns the type expression for a char column.

=signature

type_char(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mysql', 'type_char';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');

my $c1 = $t->char('data');
my $s1 = $g->type_char($c1);

is $s1, 'char(1)';

my $c2 = $t->char('data', 'size' => 10);
my $s2 = $g->type_char($c2);

is $s2, 'char(10)';

ok 1 and done_testing;
