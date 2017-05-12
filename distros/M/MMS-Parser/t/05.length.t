# vim: filetype=perl :
use Test::More tests => 570;
use lib 't/lib';
use Test::MMS::Parser;

BEGIN {
   use_ok('MMS::Parser');
}

my $parser = MMS::Parser->create();

check_cases(
   $parser,
   {
      'length_' => [
         ["\x00"                 => 0],
         ["\x01"                 => 1],
         ["\x10"                 => 16],
         ["\x7F"                 => 127],
         ["\xFF\x0F"             => 0x3F8F],
         ["\x82\x8F\x25"         => 0x87A5],
         ["\x8F\xFF\xFF\xFF\x7F" => 0xFF_FF_FF_FF],
      ],
      long_length => [
         ["\x1f\x00"                 => 0],
         ["\x1f\x01"                 => 1],
         ["\x1f\x10"                 => 16],
         ["\x1f\x7F"                 => 127],
         ["\x1f\xFF\x0F"             => 0x3F8F],
         ["\x1f\x82\x8F\x25"         => 0x87A5],
         ["\x1f\x8F\xFF\xFF\xFF\x7F" => 0xFF_FF_FF_FF],
      ],
      value_length => [
         ["\x00"                     => 0],
         ["\x01"                     => 1],
         ["\x0f"                     => 15],
         ["\x10"                     => 16],
         ["\x1e"                     => 30],
         ["\x1f\x00"                 => 0],
         ["\x1f\x01"                 => 1],
         ["\x1f\x10"                 => 16],
         ["\x1f\x7F"                 => 127],
         ["\x1f\xFF\x0F"             => 0x3F8F],
         ["\x1f\x82\x8F\x25"         => 0x87A5],
         ["\x1f\x8F\xFF\xFF\xFF\x7F" => 0xFF_FF_FF_FF],
      ],
   }
);

char_range($parser, 'length_quote', 31);

my $short_length_checker = make_checker($parser, 'short_length');
my $value_length_checker = make_checker($parser, 'value_length');
for my $index (0 .. 30) {
   $short_length_checker->(chr($index), $index);
   $value_length_checker->(chr($index), $index);
}
$short_length_checker->(chr(31), undef);
for my $index (32 .. 255) {
   $short_length_checker->(chr($index), undef);
}
