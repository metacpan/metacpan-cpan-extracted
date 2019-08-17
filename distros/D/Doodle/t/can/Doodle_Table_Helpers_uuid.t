use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

uuid

=usage

  my $uuid = $self->uuid('reference');

=description

Registers a uuid column and returns the Command object set.

=signature

uuid(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'reference',
  method => 'uuid'
);

$test->execute;

ok 1 and done_testing;
