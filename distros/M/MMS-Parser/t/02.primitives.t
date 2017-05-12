# vim: filetype=perl :
use Test::More tests => 548;
use lib 't/lib';
use Test::MMS::Parser;

BEGIN {
   use_ok('MMS::Parser');
}

my $parser = MMS::Parser->create();

# Test 1-octet stuff like octet or uint8
my $octet_checker = make_checker($parser, 'octet');
my $uint8_checker = make_checker($parser, 'uint8');
foreach my $index (0 .. 255) {
   my $c = chr($index);
   $octet_checker->($c, $c);
   $uint8_checker->($c, $index);
}

my %tests = (
   uint16 => [
      ["\x00\x00" => 0],
      ["\x00\x01" => 1],
      ["\x00\x10" => 16],
      ["\x00\x34" => 52],
      ["\x00\x80" => 128],
      ["\x00\xFF" => 255],
      ["\x01\x00" => 256],
      ["\xFF\x00" => 0xFF00],
      ["\x0F\x0F" => 0x0F0F],
      ["\x12\x34" => 0x1234],
      ["\xFF\xFF" => 0xFFFF],
   ],

   uint32 => [
      ["\x00\x00\x00\x00" => 0],
      ["\x00\x00\x00\x01" => 1],
      ["\x00\x00\x00\x10" => 16],
      ["\x00\x00\x00\x34" => 52],
      ["\x00\x00\x00\x80" => 128],
      ["\x00\x00\x00\xFF" => 255],
      ["\x00\x00\x01\x00" => 256],
      ["\x00\x00\xFF\x00" => 0xFF00],
      ["\x00\x00\x0F\x0F" => 0x0F0F],
      ["\x00\x00\x12\x34" => 0x1234],
      ["\x00\x00\xFF\xFF" => 0xFFFF],
      ["\x00\x00\xFF\xFF" => 0xFFFF],
      ["\x00\x00\xFF\xFF" => 0xFFFF],
      ["\x00\x00\xFF\xFF" => 0xFFFF],
      ["\x12\x34\x56\x78" => 0x1234_5678],
      ["\x87\x65\x43\x21" => 0x8765_4321],
      ["\xFF\xFF\xFF\xFF" => 0xFFFF_FFFF],
   ],

   uintvar => [
      ["\x00"                 => 0],
      ["\x01"                 => 1],
      ["\x10"                 => 16],
      ["\x7F"                 => 127],
      ["\xFF\x0F"             => 0x3F8F],
      ["\x82\x8F\x25"         => 0x87A5],
      ["\x8F\xFF\xFF\xFF\x7F" => 0xFF_FF_FF_FF],
   ],
);

while (my ($subname, $spec) = each %tests) {
   my $checker = make_checker($parser, $subname);
   $checker->(@$_) foreach @$spec;
}
