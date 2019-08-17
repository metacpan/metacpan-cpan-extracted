use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

text_medium

=usage

  my $text_medium = $self->text_medium('biography');

=description

Registers a medium text column and returns the Command object set.

=signature

text_medium(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'biography',
  method => 'text_medium'
);

$test->execute;

ok 1 and done_testing;
