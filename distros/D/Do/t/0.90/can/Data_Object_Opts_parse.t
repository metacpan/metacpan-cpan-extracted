use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

parse

=usage

  my $options = $opts->parse;
  my $options = $opts->parse(['bundle']);

=description

The parse method optionally takes additional L<Getopt::Long> parser
configuration options and retuns the options found based on the object C<args>
and C<spec> values.

=signature

parse(Maybe[ArrayRef] $config) : HashRef

=type

method

=cut

# TESTING

use Data::Object::Opts;

can_ok "Data::Object::Opts", "parse";

my $opts = Data::Object::Opts->new(
  args => ['--resource', 'users', '--help'],
  spec => ['resource|r=s', 'help|h'],
  named => { method => 'resource' } # optional
);

is_deeply $opts->parse, {
  resource => 'users',
  help => 1
};

ok 1 and done_testing;
