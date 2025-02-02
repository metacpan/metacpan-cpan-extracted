#!/usr/bin/env perl
package
  t_Case05;
use MOP4Import::Declare -as_base;

use MOP4Import::Types
  Foo => [[fields =>
           [name => isa => 'Str', default => 'unknown'],
           [age => validator => +{isa => 'Int', default => 20}],
         ]]
  ;

1;
