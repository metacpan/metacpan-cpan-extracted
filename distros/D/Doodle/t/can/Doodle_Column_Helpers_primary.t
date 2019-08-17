use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

primary

=usage

  my $primary = $self->primary('id');

=description

Denotes that the column is the primary key and returns the Column object.

=signature

primary(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'id',
  method => 'primary'
);

$test->execute(sub {
  my $c = shift;

  is $c->type, 'string';
  is $c->data->{primary}, 1;
});

ok 1 and done_testing;
