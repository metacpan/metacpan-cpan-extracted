use strict;
use warnings;
use FFI::Platypus 2.00;
use Math::Complex;

my $ffi = FFI::Platypus->new(
  api  => 2,
  lang => 'Fortran',
  lib  => './complex.so',
);

$ffi->attach( complex_decompose => ['complex_16*','real_8*','real_8*'] );

complex_decompose( \(1.5 + 2.5*i), \my $r, \my $i);

print "${r} + ${i}i\n";
