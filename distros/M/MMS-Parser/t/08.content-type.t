# vim: filetype=perl :
use Test::More tests => 337;
use lib 't/lib';
use Test::MMS::Parser;

BEGIN {
   use_ok('MMS::Parser');
}

my $parser = MMS::Parser->create();

# Parameter types
my @well_known_charset_noany = (
   ["\x02\x07\xea" => 'big5'],
   ["\x02\x03\xe8" => 'iso-10646-ucs-2'],
   ["\x84"         => 'iso-8859-1'],
   ["\x85"         => 'iso-8859-2'],
   ["\x86"         => 'iso-8859-3'],
   ["\x87"         => 'iso-8859-4'],
   ["\x88"         => 'iso-8859-5'],
   ["\x89"         => 'iso-8859-6'],
   ["\x8a"         => 'iso-8859-7'],
   ["\x8b"         => 'iso-8859-8'],
   ["\x8c"         => 'iso-8859-9'],
   ["\x91"         => 'shift_JIS'],
   ["\x83"         => 'us-ascii'],
   ["\xea"         => 'utf-8'],
   ["\x81"         => 1],
);

my $wkc_checker         = make_checker($parser, 'well_known_charset');
my $any_charset_checker = make_checker($parser, 'any_charset');
$_->("\x80", '*') foreach ($wkc_checker, $any_charset_checker);
my $_wkc_wcode_checker =
  make_checker($parser, '_well_known_charset_wcode');
foreach my $spec (@well_known_charset_noany) {
   $_->(@$spec) foreach ($wkc_checker, $_wkc_wcode_checker);
}

my %tests_for = (
   well_known_media => [
      ["\x00"         => undef],
      ["\x1F"         => undef],
      [""             => undef],
      ["\x01"         => undef],
      ["\x01\x00"     => 0],
      ["\x01\x01"     => 1],
      ["\x01\xFF"     => 255],
      ["\x02\x01\x00" => 256],
   ],
   media_type => [
      ["\x1F"      => undef],
      [""          => undef],
      ["\x01"      => undef],
      ["\x01\x00"  => '*/*'],
      ["\x01\x01"  => 'text/*'],
      ["\x01\x3e"  => 'application/vnd.wap.mms-message'],
      ["\x00"      => ''],
      [" \x00"     => ' '],
      ["ciao\x00"  => "ciao"],
      ["uela'\x00" => "uela'"],

      # FIXME add examples with parameters
   ],

   field_name => [
      ["ciao\x00"          => 'ciao'],
      ["bulabula_bula\x00" => 'bulabula_bula'],
      ["bula bula\x00"     => undef],
      ["\x1Aciao\x00"      => undef],
      ["\x80"              => 0],
      ["\xFF"              => 127],
   ],
   constrained_media => [
      ["\x00"         => ''],
      [" \x00"        => ' '],
      ["\x7fciao\x00" => undef],
      ["ciao\x00"     => "ciao"],
      ["uela'\x00"    => "uela'"],
   ],
   content_type_value => [
      ["\x00"         => { text => '', media_type => '', parameters => {}}],
      [" \x00"        => { text => ' ', media_type => ' ', parameters => {}}],
      ["\x7fciao\x00" => undef],
      ["ciao\x00"     => { text => 'ciao', media_type => 'ciao', parameters => {}}],
      ["uela'\x00"    => { text => "uela'", media_type => "uela'", parameters => {}}],
   ],
);
foreach my $test (@{$tests_for{media_type}}) {
   my ($in, $out) = @$test;
   next unless defined $out;
   $in = (pack 'C*', length($in)) . $in;
   $out = { text => $out, media_type => $out, parameters => {} };
   push @{$tests_for{content_general_form}}, [$in, $out];
   push @{$tests_for{content_type_value}}, [$in, $out];
} ## end foreach my $test (@{$tests_for...
check_cases($parser, \%tests_for);

my $wkf_name_checker = make_checker($parser, 'well_known_field_name');
for my $ord (0 .. 127) {
   $wkf_name_checker->(chr($ord), undef);
   $wkf_name_checker->(chr($ord | 0x80), $ord);
}
