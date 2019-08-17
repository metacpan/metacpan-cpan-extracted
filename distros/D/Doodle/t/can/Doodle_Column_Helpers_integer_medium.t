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

Configures a medium integer (3-byte) column and returns itself.

=signature

integer_medium(Any %args) : Column

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
