use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

integer

=usage

  my $integer = $self->integer;

=description

Configures an integer (4-byte) column and returns itself.

=signature

integer(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'rank',
  method => 'integer'
);

$test->execute;

use Doodle;
use Doodle::Column::Helpers;

can_ok "Doodle::Column::Helpers", "integer";

my $d = Doodle->new;
my $c = $d->table('users')->column('rank')->integer;

isa_ok $c, 'Doodle::Column';

is $c->type, 'integer';

ok 1 and done_testing;
