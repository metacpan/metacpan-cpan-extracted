use strict;
use warnings;
use FFI::Platypus 1.00;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lang('Fortran');
$ffi->lib('./libfixed_array.so');

$ffi->attach( print_array10  => ['integer[10]'] => 'void' );
$ffi->attach( print_array2x5 => ['integer[10]'] => 'void' );

my $array = [5,10,15,20,25,30,35,40,45,50];

print_array10($array);
print_array2x5($array);


