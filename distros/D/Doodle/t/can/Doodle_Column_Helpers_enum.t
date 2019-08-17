use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

enum

=usage

  my $enum = $self->enum(options => [
    'red', 'blue', 'green'
  ]);

=description

Configures an enum column and returns itself.

=signature

enum(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'colors',
  arguments => [options => ['red', 'blue', 'green']],
  method => 'enum'
);

$test->execute(sub {
  my $c = shift;

  is_deeply $c->data->{options}, ['red', 'blue', 'green'];
});

ok 1 and done_testing;
