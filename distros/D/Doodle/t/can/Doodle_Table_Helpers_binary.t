use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

binary

=usage

  my $binary = $self->binary('resume');

=description

Registers a binary column and returns the Command object set.

=signature

binary(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'resume',
  method => 'binary'
);

$test->execute;

ok 1 and done_testing;
