use strict;
use warnings;
use FFI::C::UnionDef;

my $def = FFI::C::UnionDef->new(
  name => 'anyint_t',
  class => 'AnyInt',
  members => [
    u8  => 'uint8',
    u16 => 'uint16',
    u32 => 'uint32',
  ],
);

my $int = AnyInt->new({ u8 => 42 });
printf "0x%x\n", $int->u32;   # 0x2a on Intel
