use strict;
use warnings;
use FFI::Platypus;
use Math::Complex;

my $ffi = FFI::Platypus->new;
$ffi->lang('Fortran');
$ffi->lib('./libcomplex.so');

## complex not yet supported by FFI::Platypus
#$ffi->attach(
#  complex_combine => ['real_8*','real_8*'] => 'complex',
#  sub {
#    my($combine, $real, $imaginary) = @_;
#    my @complex;
#    $combine->(\$real, \$imaginary);
#  },
#);

$ffi->attach(
  complex_decompose => ['real_8[2]','real_8*','real_8*'] => 'void',
  sub {
    my($decompose, $complex) = @_;
    my $real;
    my $imaginary;
    $decompose->([Re($complex),Im($complex)], \$real, \$imaginary);
    ($real, $imaginary);
  },
);

my($r,$i) = complex_decompose(1.5 + 2.5*i);

print "${r} + ${i}i\n"; 
