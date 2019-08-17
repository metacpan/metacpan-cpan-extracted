use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_char

=usage

  $self->type_char($column);

  # varchar

=description

Returns the type expression for a char column.

=signature

type_char(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Sqlite', 'type_char';

my $d = Doodle->new;
my $g = Doodle::Grammar::Sqlite->new;
my $t = $d->table('users');
my $c = $t->char('data');
my $s = $g->type_char($c);

is $s, 'varchar';

ok 1 and done_testing;
