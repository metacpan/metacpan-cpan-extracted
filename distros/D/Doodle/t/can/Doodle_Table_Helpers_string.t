use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

string

=usage

  my $string = $self->string('fname');

=description

Registers a string column and returns the Command object set.

=signature

string(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'fname',
  method => 'string'
);

$test->execute;

ok 1 and done_testing;
