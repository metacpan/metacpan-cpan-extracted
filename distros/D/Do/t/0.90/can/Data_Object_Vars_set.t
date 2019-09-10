use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

set

=usage

  $vars->set('home', '/tmp'); # /tmp
  $vars->set('HOME', '/tmp'); # /tmp

=description

The set method takes a name and sets the value provided if the associated
argument exists.

=signature

set(Str $key, Maybe[Any] $value) : Any

=type

method

=cut

# TESTING

use Data::Object::Vars;

can_ok "Data::Object::Vars", "set";

local %ENV = (USER => 'root', HOME => '/root');

my $data = Data::Object::Vars->new(
  named => { iam => 'USER', root => 'HOME' }
);

is $data->set('iam'), undef;
is $data->get('iam'), undef;
is $data->get('USER'), undef;
is $data->set('root', '/tmp'), '/tmp';
is $data->get('home'), '/tmp';
is $data->get('HOME'), '/tmp';
ok !$data->set('PATH');

ok 1 and done_testing;
