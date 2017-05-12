# vim: filetype=perl :
use Test::More tests => 934;
use lib 't/lib';
use Test::MMS::Parser;

BEGIN {
   use_ok('MMS::Parser');
}

my $parser = MMS::Parser->create();

my %tests = (
   text_string => [
      ["\x00"         => ''],
      [" \x00"        => ' '],
      ["\x7fciao\x00" => 'ciao'],    # actually not standard
      ["ciao\x00"     => "ciao"],
      ["uela'\x00"    => "uela'"],
   ],
   token_text => [
      ["ciao\x00"          => 'ciao'],
      ["bulabula_bula\x00" => 'bulabula_bula'],
      ["bula bula\x00"     => undef],
      ["\xAAciao\x00"      => undef],
   ],
   quoted_string => [
      ["\x22ciao bellezze\x00" => 'ciao bellezze'],
      ["\x22\x00"              => ''],
      ["ciao bellezze\x00"     => undef],
   ],
   extension_media => [
      ["\x00"         => ''],
      [" \x00"        => ' '],
      ["\x7fciao\x00" => undef],
      ["ciao\x00"     => "ciao"],
      ["uela'\x00"    => "uela'"],
   ],
   long_integer => [
      ["\x00"         => undef],
      ["\x1F"         => undef],
      [""             => undef],
      ["\x01"         => undef],
      ["\x01\x00"     => 0],
      ["\x01\x01"     => 1],
      ["\x01\xFF"     => 255],
      ["\x02\x01\x00" => 256],
   ],
   uintvar_integer => [
      ["\x00"                 => 0],
      ["\x01"                 => 1],
      ["\x10"                 => 16],
      ["\x7F"                 => 127],
      ["\xFF\x0F"             => 0x3F8F],
      ["\x82\x8F\x25"         => 0x87A5],
      ["\x8F\xFF\xFF\xFF\x7F" => 0xFF_FF_FF_FF],
   ],
   constrained_encoding => [
      ["\x00"         => ''],
      [" \x00"        => ' '],
      ["\x7fciao\x00" => undef],
      ["ciao\x00"     => "ciao"],
      ["uela'\x00"    => "uela'"],
   ],
);
check_cases($parser, \%tests);

my $shortint_checker = make_checker($parser, 'short_integer');
foreach my $index (0 .. 127) {
   $shortint_checker->(chr($index), undef);
}
my $c_encoding_checker = make_checker($parser, 'constrained_encoding');
foreach my $index (128 .. 255) {
   $shortint_checker->(chr($index), $index - 128);
   $c_encoding_checker->(chr($index), $index - 128);
}

my $quote_checker = make_checker($parser, 'quote');
my $eos_checker   = make_checker($parser, 'end_of_string');
$quote_checker->("\x7f", "\x7f");
$quote_checker->("\x00", undef);
$eos_checker->("\x00",   "\x00");
$eos_checker->("\x7f",   undef);
for my $index (1 .. 126, 128 .. 255) {
   my $c = chr $index;
   $quote_checker->($c, undef);
   $eos_checker->($c,   undef);
}

1;
