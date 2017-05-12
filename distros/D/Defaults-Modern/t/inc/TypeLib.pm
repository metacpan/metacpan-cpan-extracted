package TypeLib;
use strict; use warnings FATAL => 'all';

use Type::Library -base;
use Type::Utils   -all;
use Types::Standard -types;

declare FooType =>
  as Str,
  where { $_ eq 'foo' };

1;
