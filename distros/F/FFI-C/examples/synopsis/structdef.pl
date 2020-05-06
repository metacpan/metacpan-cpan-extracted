use strict;
use warnings;
use FFI::Platypus 1.00;
use FFI::C::StructDef;

my $ffi = FFI::Platypus->new( api => 1 );
# See FFI::Platypus::Bundle for how bundle works.
$ffi->bundle;

my $def = FFI::C::StructDef->new(
  $ffi,
  name  => 'color_t',
  class => 'Color',
  members => [
    red   => 'uint8',
    green => 'uint8',
    blue  => 'uint8',
  ],
);

my $red = Color->new({ red => 255 });

my $green = Color->new({ green => 255 });

$ffi->attach( print_color => ['color_t'] );

print_color($red);   # [ff 00 00]
print_color($green); # [00 ff 00]

# that red is a tad bright!
$red->red( 200 );

print_color($red);   # [c8 00 00]
