use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api  => 2,
  lang => 'Fortran',
  lib  => './array.so',
);

$ffi->attach( print_array10  => ['integer[10]'] => 'void' );

my $array = [5,10,15,20,25,30,35,40,45,50];

print_array10($array);


