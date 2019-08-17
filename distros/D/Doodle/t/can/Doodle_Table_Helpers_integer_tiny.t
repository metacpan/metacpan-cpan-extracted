use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

integer_tiny

=usage

  my $integer_tiny = $self->integer_tiny('number');

=description

Registers a tiny integer (1-byte) column and returns the Command object set.

=signature

integer_tiny(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'number',
  method => 'integer_tiny'
);

$test->execute;

ok 1 and done_testing;
