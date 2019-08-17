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

Registers primary key(s) and returns the Command object set.

=signature

primary(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Table_Helpers;

my $test = Test_Doodle_Table_Helpers->new(
  table => 'users',
  column => 'id',
  method => 'primary'
);

$test->execute(sub {
  my $c = shift;

  is $c->type, 'integer';
  is $c->data->{increments}, 1;
});

ok 1 and done_testing;
