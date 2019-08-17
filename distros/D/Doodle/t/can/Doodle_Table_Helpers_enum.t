use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

enum

=usage

  my $enum = $self->enum('colors', options => [
    'red', 'blue', 'green'
  ]);

=description

Registers an enum column and returns the Command object set.

=signature

enum(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'colors',
  method => 'enum',
  arguments => [options => ['red', 'blue', 'green']]
);

my $column = $test->execute;

is_deeply $column->data->{options}, ['red', 'blue', 'green'];

ok 1 and done_testing;
