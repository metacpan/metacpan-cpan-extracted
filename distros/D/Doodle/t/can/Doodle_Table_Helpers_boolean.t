use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

boolean

=usage

  my $boolean = $self->boolean('verified');

=description

Registers a boolean column and returns the Command object set.

=signature

boolean(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'verified',
  method => 'boolean'
);

$test->execute;

ok 1 and done_testing;
