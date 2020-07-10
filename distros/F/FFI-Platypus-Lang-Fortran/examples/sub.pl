use strict;
use warnings;
use FFI::Platypus 1.00;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lang('Fortran');
$ffi->lib('./libsub.so');

$ffi->attach( add => ['integer*','integer*','integer*'] => 'void');

my $value = 0;
add(\$value, \1, \2);

print "$value\n";

