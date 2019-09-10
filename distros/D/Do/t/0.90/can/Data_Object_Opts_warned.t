use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

warned

=usage

  my $warned = $opts->warned; # $count

=description

The warned method returns the number of warnings emitted during option parsing.

=signature

warned() : Num

=type

method

=cut

# TESTING

use Data::Object::Opts;

can_ok "Data::Object::Opts", "warned";

my $opts = Data::Object::Opts->new(
  args => ['--resource', 'users', '--help'],
  spec => ['resource|r=i', 'help|h'],
  named => { method => 'resource' } # optional
);

is $opts->warned, 1;

ok 1 and done_testing;
