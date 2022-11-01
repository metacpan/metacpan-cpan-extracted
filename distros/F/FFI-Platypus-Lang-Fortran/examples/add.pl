use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api  => 2,
  lang => 'Fortran',
  lib  => './add.so',
);

$ffi->attach( add => ['integer*','integer*'] => 'integer');

print add(\1,\2), "\n";
