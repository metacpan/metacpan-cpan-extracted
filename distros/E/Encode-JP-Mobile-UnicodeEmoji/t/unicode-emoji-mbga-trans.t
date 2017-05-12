use strict;
use warnings;
use Encode;
use Encode::JP::Mobile::UnicodeEmojiMBGA;
use Encode::JP::Emoji::Property;
use Test::More;

# hare
my $auto_byte = "\xE2\x98\x80";
my $mobile_jp_unicode = "\x{E63E}";
my $softbank_byte = "\xEE\x81\x8A";
my $softbank_unicode = "\x{E04A}";


my $enc = Encode::find_encoding('x-utf8-jp-mobile-unicode-emoji-mbga');

is $enc->mime_name, 'UTF-8';
ok decode('x-utf8-e4u-unicode', $auto_byte) =~ /\p{InEmojiGoogle}/;
is decode($enc, $auto_byte), $mobile_jp_unicode;
is decode($enc, $softbank_byte), $softbank_unicode;
is encode($enc, $mobile_jp_unicode), $softbank_byte;

done_testing;
