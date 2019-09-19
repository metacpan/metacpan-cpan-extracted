use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Boolean

=abstract

Data-Object Boolean Class

=synopsis

  use Data::Object::Boolean;

  my $bool;

  $bool = Data::Object::Boolean->new; # false
  $bool = Data::Object::Boolean->new(1); # true
  $bool = Data::Object::Boolean->new(0); # false
  $bool = Data::Object::Boolean->new(''); # false
  $bool = Data::Object::Boolean->new(undef); # false

=description

This package provides functions and representation for boolean values.

=cut

use_ok "Data::Object::Boolean";

ok 1 and done_testing;
