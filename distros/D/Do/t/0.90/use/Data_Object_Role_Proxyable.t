use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Proxyable

=abstract

Data-Object Proxyable Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Proxyable';

  sub BUILDPROXY {
    my ($class, $method, @args) = @_;

    return if $method eq 'execute'; # die with method missing error

    return sub { time }; # process method call
  }

=libraries

Data::Object::Library

=description

This role provides a wrapper around the AUTOLOAD routine which processes calls
to routines which don't exist.

=cut

use_ok "Data::Object::Role::Proxyable";

ok 1 and done_testing;
