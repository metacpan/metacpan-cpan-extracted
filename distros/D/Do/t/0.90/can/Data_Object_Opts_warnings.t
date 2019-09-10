use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

warnings

=usage

  my $warnings = $opts->warnings;
  my $warning = $warnings->[0][0];

  die $warning;

=description

The warnings method returns the set of warnings emitted during option parsing.

=signature

warnings() : ArrayRef[ArrayRef[Str]]

=type

method

=cut

# TESTING

use Data::Object::Opts;

can_ok "Data::Object::Opts", "warnings";

my $opts = Data::Object::Opts->new(
  args => ['--resource', 'users', '--help'],
  spec => ['resource|r=i', 'help|h'],
  named => { method => 'resource' } # optional
);

like $opts->warnings->[0][0], qr/.*users.*invalid.*resource.*number expected.*/;

ok 1 and done_testing;
