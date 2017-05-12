use strict;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;
$ffi->lang("Fortran");
$ffi->lib("./libvar_array.so");

$ffi->attach( sum_array => ['integer*','integer[]'] => 'integer',
  sub {
    my $f = shift;
    my $size = scalar @_;
    $f->(\$size, \@_);
  }
);

my @a = (1..10);
my @b = (25..30);

print sum_array(@a), "\n";
print sum_array(@b), "\n";
