use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_json

=usage

  $self->type_json($column);

  # text

=description

Returns the type expression for a json column.

=signature

type_json(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Sqlite', 'type_json';

my $d = Doodle->new;
my $g = Doodle::Grammar::Sqlite->new;
my $t = $d->table('users');
my $c = $t->json('data');
my $s = $g->type_json($c);

is $s, 'text';

ok 1 and done_testing;
