use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

integer_big_unsigned

=usage

  my $integer_big_unsigned = $self->integer_big_unsigned;

=description

Configures an unsigned big integer (8-byte) column and returns itself.

=signature

integer_big_unsigned(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'number',
  method => 'integer_big_unsigned'
);

$test->execute;

ok 1 and done_testing;
