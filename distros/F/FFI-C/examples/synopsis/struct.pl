use strict;
use warnings;
use FFI::C::StructDef;

my $def = FFI::C::StructDef->new(
  name  => 'color_t',
  class => 'Color',
  members => [
    red   => 'uint8',
    green => 'uint8',
    blue  => 'uint8',
  ],
);

my $red = $def->create({ red => 255 });    # creates a FFI::C::Stuct

printf "[%02x %02x %02x]\n", $red->red, $red->green, $red->blue;  # [ff 00 00]

# that red is too bright!
$red->red(200);

printf "[%02x %02x %02x]\n", $red->red, $red->green, $red->blue;  # [c8 00 00]


my $green = Color->new({ green => 255 });  # creates a FFI::C::Stuct

printf "[%02x %02x %02x]\n", $green->red, $green->green, $green->blue;  # [00 ff 00]
