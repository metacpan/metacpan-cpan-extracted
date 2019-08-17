use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_text_medium

=usage

  $self->type_text_medium($column);

  # mediumtext

=description

Returns the type expression for a text_medium column.

=signature

type_text_medium(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mysql', 'type_text_medium';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $c = $t->text_medium('data');
my $s = $g->type_text_medium($c);

is $s, 'mediumtext';

ok 1 and done_testing;
