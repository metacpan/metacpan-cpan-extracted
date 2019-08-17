use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

integer_medium

=usage

  my $integer_medium = $self->integer_medium('number');

=description

Registers a medium integer (3-byte) column and returns the Command object set.

=signature

integer_medium(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'number',
  method => 'integer_medium'
);

$test->execute;

ok 1 and done_testing;
