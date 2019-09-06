use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Exception

=abstract

Data-Object Exception Class

=synopsis

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new;

  die $exception;

  $exception->throw('Oops');

  die $exception->new('Oops')->trace(0);

  "$exception" # renders exception message

=libraries

Data::Object::Library

=description

This package provides functionality for creating, throwing, and introspecting
exception objects.

=cut

use_ok "Data::Object::Exception";

ok 1 and done_testing;
