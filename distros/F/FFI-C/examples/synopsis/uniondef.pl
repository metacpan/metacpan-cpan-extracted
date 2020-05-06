use strict;
use warnings;
use FFI::Platypus 1.00;
use FFI::C::UnionDef;

my $ffi = FFI::Platypus->new( api => 1 );
# See FFI::Platypus::Bundle for how bundle works.
$ffi->bundle;

my $def = FFI::C::UnionDef->new(
  $ffi,
  name => 'anyint_t',
  class => 'AnyInt',
  members => [
    u8  => 'uint8',
    u16 => 'uint16',
    u32 => 'uint32',
  ],
);

$ffi->attach( print_anyint_as_u32 => ['anyint_t'] );

my $int = AnyInt->new({ u8 => 42 });
print_anyint_as_u32($int);  # 0x2a on Intel,
