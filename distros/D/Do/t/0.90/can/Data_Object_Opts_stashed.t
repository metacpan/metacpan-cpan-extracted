use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

stashed

=usage

  $opts->stashed; # {...}

=description

The stashed method returns the stashed data associated with the object.

=signature

stashed() : HashRef

=type

method

=cut

# TESTING

use Data::Object::Opts;

can_ok "Data::Object::Opts", "stashed";

my $opts = Data::Object::Opts->new(
  args => ['--resource', 'users', '--help'],
  spec => ['resource|r=s', 'help|h'],
  named => { method => 'resource' } # optional
);

is_deeply $opts->stashed, {
  resource => 'users',
  help => 1
};

ok 1 and done_testing;
