use strict;
use warnings;
use FFI::Platypus 1.00;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lang('Fortran');
$ffi->lib('./libfib.so');

$ffi->attach( fib => ['integer*'] => 'integer' );

for(1..10)
{
  print fib(\$_), "\n";
}
