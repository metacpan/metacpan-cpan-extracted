use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

get

=usage

  $vars->get('home'); # $ENV{HOME}
  $vars->get('HOME'); # $ENV{HOME}

=description

The get method takes a name and returns the associated value.

=signature

get(Str $key) : Any

=type

method

=cut

# TESTING

use Data::Object::Vars;

can_ok "Data::Object::Vars", "get";

local %ENV = (USER => 'root', HOME => '/root');

my $data = Data::Object::Vars->new(
  named => { iam => 'USER', root => 'HOME' }
);

is $data->get('iam'), 'root';
is $data->get('user'), 'root';
is $data->get('USER'), 'root';
is $data->get('root'), '/root';
is $data->get('home'), '/root';
is $data->get('HOME'), '/root';
ok !$data->exists('PATH');

ok 1 and done_testing;
