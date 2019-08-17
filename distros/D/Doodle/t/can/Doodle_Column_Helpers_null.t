use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

null

=usage

  my $null = $self->null;

=description

Denotes that the Column is nullable and returns itself.

=signature

null(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'verified',
  method => 'null'
);

$test->execute(sub {
  my $c = shift;

  is $c->type, 'string';
  is $c->data->{nullable}, 1;
});

ok 1 and done_testing;
