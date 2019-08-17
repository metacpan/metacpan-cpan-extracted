use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_binary

=usage

  $self->type_binary($column);

  # bytea

=description

Returns the type expression for a binary column.

=signature

type_binary(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Postgres', 'type_binary';

my $d = Doodle->new;
my $g = Doodle::Grammar::Postgres->new;
my $t = $d->table('users');
my $c = $t->binary('data');
my $s = $g->type_binary($c);

is $s, 'bytea';

ok 1 and done_testing;
