use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Args

=abstract

Data-Object Command-line Arguments

=synopsis

  use Data::Object::Args;

  my $args = Data::Object::Args->new(
    named => { command => 0, action => 1 }
  );

  $args->get(0); # $ARGV[0]
  $args->get(1); # $ARGV[1]
  $args->action; # $ARGV[1]
  $args->command; # $ARGV[0]
  $args->exists(0); # exists $ARGV[0]
  $args->exists('command'); # exists $ARGV[0]
  $args->get('command'); # $ARGV[0]

=libraries

Data::Object::Library

=attributes

named(HashRef, opt, ro)

=description

This package provides an object-oriented interface to the process' command-line
arguments.

=cut

use_ok "Data::Object::Args";

ok 1 and done_testing;
