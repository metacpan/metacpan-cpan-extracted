use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

text_long

=usage

  my $text_long = $self->text_long('biography');

=description

Registers a long text column and returns the Command object set.

=signature

text_long(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'biography',
  method => 'text_long'
);

$test->execute;

ok 1 and done_testing;
