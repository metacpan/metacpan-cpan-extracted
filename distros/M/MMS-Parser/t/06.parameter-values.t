# vim: filetype=perl :
use Test::More tests => 313;
use lib 't/lib';
use Test::MMS::Parser;

BEGIN {
   use_ok('MMS::Parser');
}

my $parser = MMS::Parser->create();

my $no_value_checker = make_checker($parser, 'no_value');
$no_value_checker->(chr(0), '');
for my $index (1 .. 255) {
   $no_value_checker->(chr($index), undef);
}

check_cases(
   $parser,
   {
      text_value => [
         ["\x00"                  => ''],
         ["ciao\x00"              => 'ciao'],
         ["bulabula_bula\x00"     => 'bulabula_bula'],
         ["bula bula\x00"         => undef],
         ["\xAAciao\x00"          => undef],
         ["\x22ciao bellezze\x00" => 'ciao bellezze'],
         ["\x22\x00"              => ''],
         ["ciao bellezze\x00"     => undef],

      ],
      integer_value => [
         ["\x00"         => undef],
         ["\x1F"         => undef],
         [""             => undef],
         ["\x01"         => undef],
         ["\x01\x00"     => 0],
         ["\x01\x01"     => 1],
         ["\x01\xFF"     => 255],
         ["\x02\x01\x00" => 256],
      ],
      date_value => [
         ["\x00"         => undef],
         ["\x1F"         => undef],
         [""             => undef],
         ["\x01"         => undef],
         ["\x01\x00"     => 0],
         ["\x01\x01"     => 1],
         ["\x01\xFF"     => 255],
         ["\x02\x01\x00" => 256],
      ],
      delta_seconds_value => [
         ["\x00"         => undef],
         ["\x1F"         => undef],
         [""             => undef],
         ["\x01"         => undef],
         ["\x01\x00"     => 0],
         ["\x01\x01"     => 1],
         ["\x01\xFF"     => 255],
         ["\x02\x01\x00" => 256],
      ],
      q_value => [
         ["\x01"     => 0],
         ["\x0b"     => 0.1],
         ["\x0f"     => 0.14],
         ["\x64"     => 0.99],
         ["\x65"     => 0.001],
         ["\x83\x31" => 0.333],
         ["\x88\x4b" => 0.999],
         ["\x88\x4c" => undef],
      ],
      version_value => [
         ["\x90"      => '1.0'],
         ["\x9f"      => '1'],
         ["\xa5"      => '2.5'],
         ["1.0.1\x00" => '1.0.1'],
         ["\x00"      => ''],
         ["\x01"      => undef],
      ],
      _short_integer_version => [
         ["\x90"      => '1.0'],
         ["\x9f"      => '1'],
         ["\xa5"      => '2.5'],
         ["\x01"      => undef],
      ],
      uri_value => [    # Non standard tests, should be better FIXME
         ["\x00"         => ''],
         [" \x00"        => ' '],
         ["\x7fciao\x00" => 'ciao'],    # actually not standard
         ["ciao\x00"     => "ciao"],
         ["uela'\x00"    => "uela'"],
         ["http://www.polettix.it\x00" => 'http://www.polettix.it'],
      ],
   }
);
