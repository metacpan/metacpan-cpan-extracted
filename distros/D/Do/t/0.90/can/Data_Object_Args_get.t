use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

get

=usage

  $args->get(0); # $ARGV[0]
  $args->get('command'); # $ARGV[0]

=description

The get method takes a name or index and returns the associated value.

=signature

get(Str $key) : Any

=type

method

=cut

# TESTING

use Data::Object::Args;

can_ok "Data::Object::Args", "get";

local @ARGV = ('--command', 'post', '--action', 'users');

my $data = Data::Object::Args->new(
  named => { command => 0, action => 2 }
);

is $data->get(0), '--command';
is $data->get('command'), '--command';
is $data->get(1), 'post';
is $data->get('action'), '--action';
is $data->get(2), '--action';
is $data->get(3), 'users';
ok !$data->get(4);

ok 1 and done_testing;
