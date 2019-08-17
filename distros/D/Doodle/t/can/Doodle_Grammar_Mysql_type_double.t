use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_double

=usage

  $self->type_double($column);

  # double(5, 2)

=description

Returns the type expression for a double column.

=signature

type_double(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mysql', 'type_double';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $c = $t->double('data');
my $s = $g->type_double($c);

is $s, 'double(5, 2)';

ok 1 and done_testing;
