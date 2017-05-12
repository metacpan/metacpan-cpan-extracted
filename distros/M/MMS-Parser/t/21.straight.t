# vim: filetype=perl :
use Test::More 'no_plan';
use lib 't/lib';
use Test::MMS::Parser;

BEGIN {
   use_ok('MMS::Parser');
}

my $parser = MMS::Parser->create();

my @encoded_string_value_tests = (
   ["\x00"         => {text => ''}],
   [" \x00"        => {text => ' '}],
   ["\x7fciao\x00" => {text => 'ciao'}],    # actually not standard
   ["ciao\x00"     => {text => "ciao"}],
   ["uela'\x00"    => {text => "uela'"}],

   ["\x01\x84\x00"         => {charset => "\x84", text => ''}],
   ["\x01\x84 \x00"        => {charset => "\x84", text => ' '}],
   ["\x01\x84\x7fciao\x00" => {charset => "\x84", text => 'ciao'}]
   ,                                        # actually not standard
   ["\x01\x84ciao\x00"  => {charset => "\x84", text => "ciao"}],
   ["\x01\x84uela'\x00" => {charset => "\x84", text => "uela'"}],
);
my $esv_checker = make_checker($parser, 'encoded_string_value');
$esv_checker->(@$_) foreach @encoded_string_value_tests;


########################################################################
#
# ADDRESSES
#
my @esv_for_address = map {
   my ($code, $href) = @$_;
   my %hash = %$href;        # copy, first level suffices here
   my $text = $hash{text};
   if ($text =~ m{\A (.+) / TYPE = (\w+) \z}xms) {
      $hash{address} = $1;
      $hash{TYPE}    = $2;
   }
   else {
      $hash{address} = $text;
   }
   [$code, \%hash];
} @encoded_string_value_tests;

my @address_specific_tests = (
   [
      "12345678/TYPE=PLMN\x00" =>
        {text => '12345678/TYPE=PLMN', address => '12345678', TYPE => 'PLMN'}
   ],
   [
      "foo\@example.com\x00" =>
        {text => 'foo@example.com', address => 'foo@example.com' }
   ],

   [
      "\x01\x{84}12345678/TYPE=PLMN\x00" =>
        {text => '12345678/TYPE=PLMN', address => '12345678', TYPE => 'PLMN', charset => "\x84"}
   ],
   [
      "\x01\x{84}foo\@example.com\x00" =>
        {text => 'foo@example.com', address => 'foo@example.com', charset => "\x84" }
   ],
);

# Tests specifications. Each name points to an anon array, comprising:
# * the code (e.g. bcc is 0x01)
#
my %tests_for = (
   _address => [0x00, @esv_for_address, @address_specific_tests ],
   bcc => [0x01, @esv_for_address, @address_specific_tests ],
   cc  => [0x02, @esv_for_address, @address_specific_tests ],
   to  => [0x17, @esv_for_address, @address_specific_tests ],
);

while (my ($radix, $specs) = each %tests_for) {
   my ($code, @tests) = @$specs;

   my $value_checker  = make_checker($parser, $radix . '_value');
   foreach my $tspec (@tests) {
      my ($input, $expected) = @$tspec;
      $value_checker->($input, $expected);
   }

   next if substr($radix, 0, 1) eq '_'; # Ensure it's a real header

   $code = chr($code | 0x80);
   my $header_checker = make_checker($parser, $radix . '_head');
   foreach my $tspec (@tests) {
      my ($input, $expected) = @$tspec;
      $header_checker->($code . $input, [$radix . '_head', $expected]);
   }
} ## end while (my ($radix, $specs...


########################################################################
#
# Content-location
#
my @text_string_tests = (
      ["\x00"         => ''],
      [" \x00"        => ' '],
      ["\x7fciao\x00" => 'ciao'],    # actually not standard
      ["ciao\x00"     => "ciao"],
      ["uela'\x00"    => "uela'"],
   );

__END__
* _address_value
* bcc_value
* cc_value
* to_value

content_location_value
uri_value
delivery_report_value
_mixed_time_value
_mtv_token
delivery_time_value
encoded_string_value
_charset_part
expiry_value
from_value
message_class_value
class_identifier
message_id_value
message_type_value
message_size_value
MMS_version_value
priority_value
read_reply_value
report_allowed_value
response_status_value
response_text_value
sender_visibility_value
status_value
subject_value
transaction_id_value
