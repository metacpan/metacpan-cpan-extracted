use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_text

=usage

  $self->type_text($column);

  # text

=description

Returns the type expression for a text column.

=signature

type_text(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mysql', 'type_text';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $c = $t->text('data');
my $s = $g->type_text($c);

is $s, 'text';

ok 1 and done_testing;
