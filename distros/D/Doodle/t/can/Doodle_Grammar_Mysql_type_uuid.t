use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type_uuid

=usage

  $self->type_uuid($column);

  # char(36)

=description

Returns the type expression for a uuid column.

=signature

type_uuid(Column $column) : Str

=type

method

=cut

# TESTING

use Doodle;

use_ok 'Doodle::Grammar::Mysql', 'type_uuid';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $c = $t->uuid('data');
my $s = $g->type_uuid($c);

is $s, 'char(36)';

ok 1 and done_testing;
