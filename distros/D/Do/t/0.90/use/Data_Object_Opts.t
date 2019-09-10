use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Opts

=abstract

Data-Object Command-line Options

=synopsis

  use Data::Object::Opts;

  my $opts = Data::Object::Opts->new(
    args => ['--resource', 'users', '--help'],
    spec => ['resource|r=s', 'help|h'],
    named => { method => 'resource' } # optional
  );

  $opts->method; # $resource
  $opts->get('resource'); # $resource

  $opts->help; # $help
  $opts->get('help'); # $help

=libraries

Data::Object::Library

=attributes

args(ArrayRef[Str], opt, ro)
spec(ArrayRef[Str], opt, ro)
named(HashRef, opt, ro)

=description

This package provides an object-oriented interface to the process' command-line
options.

=cut

use_ok "Data::Object::Opts";

ok 1 and done_testing;
