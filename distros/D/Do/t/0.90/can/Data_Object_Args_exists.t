use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

exists

=usage

  $args->exists(0); # exists $ARGV[0]
  $args->exists('command'); # exists $ARGV[0]

=description

The exists method takes a name or index and returns truthy if an associated
value exists.

=signature

exists(Str $key) : Any

=type

method

=cut

# TESTING

use Data::Object::Args;

can_ok "Data::Object::Args", "exists";

local @ARGV = ('--command', 'post', '--action', 'users');

my $data = Data::Object::Args->new(
  named => { command => 0, action => 1 }
);

ok $data->exists(0);
ok $data->exists('command');
ok $data->exists(1);
ok $data->exists('action');
ok $data->exists(2);
ok $data->exists(3);
ok !$data->exists(4);

ok 1 and done_testing;
