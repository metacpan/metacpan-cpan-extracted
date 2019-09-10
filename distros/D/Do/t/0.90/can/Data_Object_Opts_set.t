use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

set

=usage

  $opts->set('method', 'people'); # people
  $opts->set('resource', 'people'); # people

=description

The set method takes a name and sets the value provided if the associated
argument exists.

=signature

set(Str $key, Maybe[Any] $value) : Any

=type

method

=cut

# TESTING

use Data::Object::Opts;

can_ok "Data::Object::Opts", "set";

my $opts = Data::Object::Opts->new(
  args => ['--resource', 'users', '--help'],
  spec => ['resource|r=s', 'help|h'],
  named => { method => 'resource' } # optional
);

is $opts->set('method', 'people'), 'people';
is $opts->get('method'), 'people';
is $opts->get('resource'), 'people';
is $opts->set('help'), undef;
is $opts->get('help'), undef;

ok 1 and done_testing;
