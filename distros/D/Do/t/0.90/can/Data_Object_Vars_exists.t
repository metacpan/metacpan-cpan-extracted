use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

exists

=usage

  $vars->exists('home'); # exists $ENV{HOME}
  $vars->exists('HOME'); # exists $ENV{HOME}

=description

The exists method takes a name and returns truthy if an associated value
exists.

=signature

exists(Str $key) : Any

=type

method

=cut

# TESTING

use Data::Object::Vars;

can_ok "Data::Object::Vars", "exists";

local %ENV = (USER => 'root', HOME => '/root');

my $data = Data::Object::Vars->new(
  named => { iam => 'USER', root => 'HOME' }
);

ok $data->exists('iam');
ok $data->exists('user');
ok $data->exists('USER');
ok $data->exists('root');
ok $data->exists('home');
ok $data->exists('HOME');
ok !$data->exists('PATH');

ok 1 and done_testing;
