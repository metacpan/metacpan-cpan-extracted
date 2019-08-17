use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

integer_unsigned

=usage

  my $integer_unsigned = $self->integer_unsigned('number');

=description

Registers an unsigned integer (4-byte) column and returns the Command object set.

=signature

integer_unsigned(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'number',
  method => 'integer_unsigned'
);

$test->execute;

ok 1 and done_testing;
