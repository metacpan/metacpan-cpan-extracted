use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

name

=usage

  $opts->name('method'); # resource
  $opts->name('resource'); # resource

=description

The name method takes a name and returns the stash key if the the associated
value exists.

=signature

name(Str $key) : Any

=signature

name(Str $key) : Any

=type

method

=cut

# TESTING

use Data::Object::Opts;

can_ok "Data::Object::Opts", "name";

my $opts = Data::Object::Opts->new(
  args => ['--resource', 'users', '--help'],
  spec => ['resource|r=s', 'help|h'],
  named => { method => 'resource' } # optional
);

is $opts->name('method'), 'resource';
is $opts->name('resource'), 'resource';

ok 1 and done_testing;
