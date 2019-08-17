use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

char

=usage

  my $char = $self->char('level', size => 2);

=description

Registers a char column and returns the Command object set.

=signature

char(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'level',
  method => 'char'
);

$test->execute;

ok 1 and done_testing;
