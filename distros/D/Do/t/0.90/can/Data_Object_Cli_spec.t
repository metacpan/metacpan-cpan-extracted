use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

spec

=usage

  =pod spec

  resource|r=s, verbose|v, help|h

  =cut

  $self->spec;

  # using the options

  $self->opts->resource;
  $self->opts->verbose;

  $self->opts->resource($new_resource);
  $self->opts->verbose(0);

=description

The spec method returns an arrayref of L<Getopt::Long> option specs. By
default, this package look for those specs as a comma-separated list in the POD
section named "spec", short for "options specifications". These options are
accessible as methods on the L<Data::Object::Opts> object through the C<opts>
attribute.

=signature

spec() : ArrayRef[Str]

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok "Data::Object::Cli", "spec";

{
  package Command;

  use Moo;

  extends 'Data::Object::Cli';

  sub spec {
    [qw(resource|r=s verbose|v help|h)]
  }

  sub sign {
    {}
  }

  1;
}

local @ARGV = ('--resource', 'users', '-v');

my $command = Command->new;

my $opts = $command->opts;

is $opts->resource, 'users';
is $opts->verbose, 1;

ok 1 and done_testing;
