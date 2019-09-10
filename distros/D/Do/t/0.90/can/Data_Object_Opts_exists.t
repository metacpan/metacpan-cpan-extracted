use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

exists

=usage

  $opts->exists('method'); # exists $resource
  $opts->exists('resource'); # exists $resource

=description

The exists method takes a name and returns truthy if an associated value
exists.

=signature

exists(Str $key) : Any

=type

method

=cut

# TESTING

use Data::Object::Opts;

can_ok "Data::Object::Opts", "exists";

my $opts = Data::Object::Opts->new(
  args => ['--resource', 'users', '--help'],
  spec => ['resource|r=s', 'help|h'],
  named => { method => 'resource' } # optional
);

ok $opts->exists('method');
ok $opts->exists('resource');

ok 1 and done_testing;
