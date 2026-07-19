package GraphQL::Houtou::Runtime::LazyInfo;

use 5.014;
use strict;
use warnings;
use overload '%{}' => \&_as_hashref, fallback => 1;

sub _as_hashref {
  return GraphQL::Houtou::XS::VM::lazy_info_hashref_xs($_[0]);
}

1;
