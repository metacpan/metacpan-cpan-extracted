use strict;
use warnings;
use FFI::TinyCC;
use FFI::Platypus;

my $tcc = FFI::TinyCC->new;

$tcc->compile_string(q{
  int
  calculate_square(int value)
  {
    return value*value;
  }
});

my $value = shift @ARGV;
$value = 4 unless defined $value;

my $address = $tcc->get_symbol('calculate_square');

my $ffi = FFI::Platypus->new;
$ffi->attach([$address => 'square'] => ['int'] => 'int');

print square($value), "\n";
