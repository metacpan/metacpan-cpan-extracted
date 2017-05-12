use strict;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;
$ffi->lang('Fortran');
$ffi->lib('./libfib.so');

$ffi->attach( fib => ['integer*'] => 'integer' );

for(1..10)
{
  print fib(\$_), "\n";
}
