use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

decimal

=usage

  my $decimal = $self->decimal('point');

=description

Registers a decimal column and returns the Command object set.

=signature

decimal(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'point',
  method => 'decimal'
);

$test->execute;

ok 1 and done_testing;
