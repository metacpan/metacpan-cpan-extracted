use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_enum

=usage

  $self->type_enum($column);

  # varchar

=description

Returns the type expression for a enum column.

=signature

type_enum(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Sqlite', 'type_enum';

my $d = Doodle->new;
my $g = Doodle::Grammar::Sqlite->new;
my $t = $d->table('users');
my $c = $t->enum('data');
my $s = $g->type_enum($c);

is $s, 'varchar';

ok 1 and done_testing;
