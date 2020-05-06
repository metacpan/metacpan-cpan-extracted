use strict;
use warnings;
use FFI::C;

package ColorValue {
  FFI::C->struct([
    red   => 'uint8',
    green => 'uint8',
    blue  => 'uint8',
  ]);
}

package NamedColor {
  FFI::C->struct([
    name  => 'string(22)',
    value => 'color_value_t',
  ]);
}

package ArrayNamedColor {
  FFI::C->array(['named_color_t' => 4]);
};

my $array = ArrayNamedColor->new([
  { name => "red",    value => { red   => 255 } },
  { name => "green",  value => { green => 255 } },
  { name => "blue",   value => { blue  => 255 } },
  { name => "purple", value => { red   => 255,
                                 blue  => 255 } },
]);

# dim each color by 1/2
foreach my $color (@$array)
{
  $color->value->red  ( $color->value->red   / 2 );
  $color->value->green( $color->value->green / 2 );
  $color->value->blue ( $color->value->blue  / 2 );
}

# print out the colors
foreach my $color (@$array)
{
  printf "%s [%02x %02x %02x]\n",
    $color->name,
    $color->value->red,
    $color->value->green,
    $color->value->blue;
}

package AnyInt {
  FFI::C->union([
    u8  => 'uint8',
    u16 => 'uint16',
    u32 => 'uint32',
    u64 => 'uint64',
  ]);
}

my $int = AnyInt->new({ u8 => 42 });
print $int->u32;

