use strict;
use warnings;
use Encode;
use Encode::JP::Mobile::UnicodeEmoji;
use Encode::JP::Emoji::Property;
use Test::More;

# hare
my $auto_unicode = "\xE2\x98\x80";
my $mobile_jp_unicode = "\x{E63E}";

my $enc = Encode::find_encoding('x-utf8-jp-mobile-unicode-emoji');

is $enc->mime_name, 'UTF-8';
ok decode('x-utf8-e4u-unicode', $auto_unicode) =~ /\p{InEmojiGoogle}/;
ok decode('x-utf8-e4u-unicode', $auto_unicode) !~ /\p{InEmojiDoCoMo}/;
is decode($enc, $auto_unicode), $mobile_jp_unicode;
ok decode($enc, $auto_unicode) =~ /\p{InEmojiDoCoMo}/;
ok decode($enc, $auto_unicode) !~ /\p{InEmojiGoogle}/;
is encode($enc, $mobile_jp_unicode), $auto_unicode;

done_testing;
