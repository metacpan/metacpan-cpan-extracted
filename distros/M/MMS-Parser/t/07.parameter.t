# vim: filetype=perl :
use Test::More tests => 518;
use lib 't/lib';
use Test::MMS::Parser;

BEGIN {
   use_ok('MMS::Parser');
}

my $parser = MMS::Parser->create();

# Parameter types
my %tests_for = (
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
      ["\x90" => '1.0'],
      ["\x9f" => '1'],
      ["\xa5" => '2.5'],
      ["\x01" => undef],
   ],
   uri_value => [    # Non standard tests, should be better FIXME
      ["\x00"         => ''],
      [" \x00"        => ' '],
      ["\x7fciao\x00" => 'ciao'],    # actually not standard
      ["ciao\x00"     => "ciao"],
      ["uela'\x00"    => "uela'"],
      ["http://www.polettix.it\x00" => 'http://www.polettix.it'],
   ],
   well_known_charset => [
      ["\x80"         => '*'],                 # any charset
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
   ],
   field_name => [
      ["ciao\x00"          => 'ciao'],
      ["bulabula_bula\x00" => 'bulabula_bula'],
      ["bula bula\x00"     => undef],
      ["\x1Aciao\x00"      => undef],
      ["\x80" => 0],
      ["\xFF" => 127],
   ],
);

my %to_be_tested = (
   q_parameter               => ['1.1', 0x00, 'q_value'],
   charset_parameter         => ['1.1', 0x01, 'well_known_charset'],
   level_parameter           => ['1.1', 0x02, 'version_value'],
   type_parameter            => ['1.1', 0x03, 'integer_value'],
   name_deprecated_parameter => ['1.1', 0x05, 'text_string', 'name'],
   filename_deprecated_parameter =>
     ['1.1', 0x06, 'text_string', 'filename'],
   differences_parameter  => ['1.1', 0x07, 'field_name'],
   padding_parameter      => ['1.1', 0x08, 'short_integer'],
   type_related_parameter => ['1.2', 0x09, 'constrained_encoding'],
   start_related_deprecated_parameter =>
     ['1.2', 0x0a, 'text_string', 'start'],
   start_info_related_deprecated_parameter =>
     ['1.2', 0x0b, 'text_string', 'start_info'],
   comment_deprecated_parameter => ['1.3', 0x0c, 'text_string', 'comment'],
   domain_deprecated_parameter  => ['1.3', 0x0d, 'text_string', 'domain'],
   max_age_parameter           => ['1.3', 0x0e, 'delta_seconds_value'],
   path_deprecated_parameter   => ['1.3', 0x0f, 'text_string', 'path'],
   secure_parameter            => ['1.3', 0x10, 'no_value'],
   SEC_wbxml_parameter         => ['1.4', 0x11, 'short_integer', 'SEC'],
   MAC_wbxml_parameter         => ['1.4', 0x12, 'text_value', 'MAC'],
   creation_date_parameter     => ['1.4', 0x13, 'date_value'],
   modification_date_parameter => ['1.4', 0x14, 'date_value'],
   read_date_parameter         => ['1.4', 0x15, 'date_value'],
   size_parameter              => ['1.4', 0x16, 'integer_value'],
   name_parameter              => ['1.4', 0x17, 'text_value'],
   filename_parameter          => ['1.4', 0x18, 'text_value'],
   start_related_parameter     => ['1.4', 0x19, 'text_value', 'start'],
   start_info_related_parameter =>
     ['1.4', 0x1a, 'text_value', 'start_info'],
   comment_parameter => ['1.4', 0x1b, 'text_value'],
   domain_parameter  => ['1.4', 0x1c, 'text_value'],
   path_parameter    => ['1.4', 0x1d, 'text_value'],
);

my $typed_parameter_checker = make_checker($parser, 'typed_parameter');
my ($accumulated_text, @expected_outputs);
while (my ($subname, $spec) = each %to_be_tested) {
   my $checker = make_checker($parser, $subname);
   my ($encoding, $code, $type, $name) = @$spec;
   $code = chr($code | 0x80);
   ($name = $subname) =~ s/_parameter// unless $name;
   my %template = (encoding => $encoding, name => $name);
   foreach my $test (@{$tests_for{$type}}) {
      my ($input, $output) = @$test;
      $input = $code . $input;
      my $expected;
      if (defined($output)) {
         $expected = {%template, value => $output};
         $accumulated_text .= $input;
         push @expected_outputs, $expected;
      }
      $checker->($input,                 $expected);
      $typed_parameter_checker->($input, $expected);
   } ## end foreach my $test (@{$tests_for...
} ## end while (my ($subname, $spec...

my $at = $accumulated_text;
my @eo = @expected_outputs;
while (length $at) {
   my $res = $parser->typed_parameter(\$at);
   my $exp = shift @eo;
   is_deeply($res, $exp,
      'typed parameter on repeated sequence (' . $exp->{name} . ')');
} ## end while (length $at)

my @untyped_tests = (
   [["ciao\x00" => "\x00"]      => {name => 'ciao', value => ''}],
   [["ciao\x00" => "pippo\x00"] => {name => 'ciao', value => 'pippo'}],
   [
      ["ciao\x00" => "\x22pluto e topo\@lino\x00"] =>
        {name => 'ciao', value => 'pluto e topo@lino'}
   ],
   [["ciao\x00"  => ""]         => undef],
   [["prova\x00" => "\x01\x00"] => {name => 'prova', value => 0}],
   [["prova\x00" => "\x01\x01"] => {name => 'prova', value => 1}],
   [
      ["bula_bula\x00" => "\x01\xFF"] =>
        {name => 'bula_bula', value => 255}
   ],
   [
      ["ariciao\x00" => "\x02\x01\x00"] =>
        {name => 'ariciao', value => 256}
   ],
);

my $untyped_parameter_checker = make_checker($parser, 'untyped_parameter');
my $untyped_value_checker     = make_checker($parser, 'untyped_value');
my ($atu, @eou);
foreach my $spec (@untyped_tests) {
   my ($input_ref, $output) = @$spec;
   my $input = join '', @$input_ref;
   $untyped_parameter_checker->($input, $output);
   if (defined($output)) {
      $untyped_value_checker->($input_ref->[1], $output->{value});
      $atu .= $input;
      push @eou, $output;
   }
} ## end foreach my $spec (@untyped_tests)

$accumulated_text .= $atu;
push @expected_outputs, @eou;
while (length $atu) {
   my $res = $parser->untyped_parameter(\$atu);
   my $exp = shift @eou;
   is_deeply($res, $exp,
      'untyped parameter on repeated sequence (' . $exp->{name} . ')');
} ## end while (length $atu)

while (length $accumulated_text) {
   my $res = $parser->parameter(\$accumulated_text);
   my $exp = shift @expected_outputs;
   is_deeply($res, $exp,
      'parameter on repeated sequence (' . $exp->{name} . ')');
} ## end while (length $accumulated_text)
