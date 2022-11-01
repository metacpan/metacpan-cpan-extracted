use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api  => 2,
  lang => 'Fortran',
  lib  => './sub.so',
);

$ffi->attach( add => ['integer*','integer*','integer*'] );

my $value = 0;
add(\$value, \1, \2);

print "$value\n";

