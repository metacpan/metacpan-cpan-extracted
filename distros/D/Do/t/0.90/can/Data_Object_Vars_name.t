use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

name

=usage

  $vars->name('root'); # HOME
  $vars->name('home'); # HOME
  $vars->name('HOME'); # HOME

=description

The name method takes a name and returns stash key if the the associated value
exists.

=signature

name(Str $key) : Any

=type

method

=cut

# TESTING

use Data::Object::Vars;

can_ok "Data::Object::Vars", "name";

local %ENV = (USER => 'root', HOME => '/root');

my $data = Data::Object::Vars->new(
  named => { iam => 'USER', root => 'HOME' }
);

is $data->name('iam'), 'USER';
is $data->name('user'), 'USER';
is $data->name('USER'), 'USER';
is $data->name('root'), 'HOME';
is $data->name('home'), 'HOME';
is $data->name('HOME'), 'HOME';
ok !$data->exists('PATH');

ok 1 and done_testing;
