use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

get

=usage

  $opts->get('method'); # $resource
  $opts->get('resource'); # $resource

=description

The get method takes a name and returns the associated value.

=signature

get(Str $key) : Any

=type

method

=cut

# TESTING

use Data::Object::Opts;

can_ok "Data::Object::Opts", "get";

my $opts = Data::Object::Opts->new(
  args => ['--resource', 'users', '--help'],
  spec => ['resource|r=s', 'help|h'],
  named => { method => 'resource' } # optional
);

is $opts->get('method'), 'users';
is $opts->get('resource'), 'users';
is $opts->get('help'), 1;

ok 1 and done_testing;
