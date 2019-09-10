use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

stashed

=usage

  $args->stashed; # {...}

=description

The stashed method returns the stashed data associated with the object.

=signature

stashed() : HashRef

=type

method

=cut

# TESTING

use Data::Object::Args;

can_ok "Data::Object::Args", "stashed";

local @ARGV = ('--command', 'post', '--action', 'users');

my $data = Data::Object::Args->new(
  named => { command => 0, action => 2 }
);

is_deeply $data->stashed, {
  '0' => '--command',
  '1' => 'post',
  '2' => '--action',
  '3' => 'users'
};

ok 1 and done_testing;
