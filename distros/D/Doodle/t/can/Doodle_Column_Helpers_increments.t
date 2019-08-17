use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

increments

=usage

  my $increments = $self->increments;

=description

Denotes that the column auto-increments and returns the Column object.

=signature

increments() : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'id',
  method => 'increments'
);

$test->execute(sub {
  my $c = shift;

  is $c->type, 'integer';
  is $c->data->{increments}, 1;
});

ok 1 and done_testing;
