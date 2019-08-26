use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::State

=abstract

Data-Object Singleton Declaration

=synopsis

  package Registry;

  use Data::Object::State;

  extends 'Environment';

  1;

=description

This package modifies the consuming package making it a singleton.

=cut

use_ok "Data::Object::State";

ok 1 and done_testing;
