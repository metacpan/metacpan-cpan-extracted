use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

stashed

=usage

  $vars->stashed; # {...}

=description

The stashed method returns the stashed data associated with the object.

=signature

stashed() : HashRef

=type

method

=cut

# TESTING

use Data::Object::Vars;

can_ok "Data::Object::Vars", "stashed";

local %ENV = (USER => 'root', HOME => '/root');

my $data = Data::Object::Vars->new(
  named => { iam => 'USER', root => 'HOME' }
);

is_deeply $data->stashed, {
  USER => 'root',
  HOME => '/root'
};

ok 1 and done_testing;
