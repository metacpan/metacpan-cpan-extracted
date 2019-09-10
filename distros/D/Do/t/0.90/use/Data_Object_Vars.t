use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Vars

=abstract

Data-Object Environment Variables

=synopsis

  use Data::Object::Vars;

  my $vars = Data::Object::Vars->new(
    named => { iam => 'USER', root => 'HOME' }
  );

  $vars->root; # $ENV{HOME}
  $vars->home; # $ENV{HOME}
  $vars->get('home'); # $ENV{HOME}
  $vars->get('HOME'); # $ENV{HOME}

  $vars->iam; # $ENV{USER}
  $vars->user; # $ENV{USER}
  $vars->get('user'); # $ENV{USER}
  $vars->get('USER'); # $ENV{USER}

=libraries

Data::Object::Library

=attributes

named(HashRef, opt, ro)

=description

This package provides an object-oriented interface to the process' environment
variables.

=cut

use_ok "Data::Object::Vars";

ok 1 and done_testing;
