use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

timestamp

=usage

  my $timestamp = $self->timestamp('verified');

=description

Registers a timestamp column and returns the Command object set.

=signature

timestamp(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'verified',
  method => 'timestamp'
);

$test->execute;

ok 1 and done_testing;
