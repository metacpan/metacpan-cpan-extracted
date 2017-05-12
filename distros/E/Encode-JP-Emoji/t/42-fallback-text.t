use strict;
use warnings;
use lib 't';
use Test::More;
use EncodeUpdate;
use Encode;
use Encode::JP::Emoji;
use Encode::JP::Emoji::FB_EMOJI_TEXT;
no utf8;    # utf-8 encoded but not flagged

plan tests => 25;

# utf8

my $text;
$text = encode('x-utf8-e4u-none-pp' => "\x{E644}", FB_EMOJI_TEXT());
is $text, '[霧]', 'fog docomo';
$text = encode('x-utf8-e4u-none-pp' => "\x{FE006}", FB_EMOJI_TEXT());
is $text, '[霧]', 'fog google';

$text = encode('x-utf8-e4u-none-pp' => "\x{E71F}", FB_EMOJI_TEXT());
is $text, '[腕時計]', 'watch docomo';
$text = encode('x-utf8-e4u-none-pp' => "\x{FE01D}", FB_EMOJI_TEXT());
is $text, '[腕時計]', 'watch google';
$text = encode('x-utf8-e4u-none-pp' => "\x{231A}", FB_EMOJI_TEXT());
is $text, '[腕時計]', 'watch unicode';

$text = encode('x-utf8-e4u-none-pp' => "\x{E349}", FB_EMOJI_TEXT());
is $text, '[トマト]', 'tomato softbank3g';
$text = encode('x-utf8-e4u-none-pp' => "\x{FE055}", FB_EMOJI_TEXT());
is $text, '[トマト]', 'tomato google';

$text = encode('x-utf8-e4u-none-pp' => "\x{E037}", FB_EMOJI_TEXT());
is $text, '[教会]', 'church softbank3g';
$text = encode('x-utf8-e4u-none-pp' => "\x{FE4BB}", FB_EMOJI_TEXT());
is $text, '[教会]', 'church google';
$text = encode('x-utf8-e4u-none-pp' => "\x{26EA}", FB_EMOJI_TEXT());
is $text, '[教会]', 'church unicode';

$text = encode('x-utf8-e4u-none-pp' => "\x{E5D8}", FB_EMOJI_TEXT());
is $text, '[風呂]', 'church softbank3g';
$text = encode('x-utf8-e4u-none-pp' => "\x{E13F}", FB_EMOJI_TEXT());
is $text, '[風呂]', 'church google';
$text = encode('x-utf8-e4u-none-pp' => "\x{1F6C0}", FB_EMOJI_TEXT());
is $text, '[風呂]', 'church unicode';

# sjis

$text = "\xF3\x4D";
Encode::from_to($text, 'x-sjis-e4u-kddiweb', 'x-utf8-e4u-docomo', FB_EMOJI_TEXT());
is $text, '[夕焼け]', 'yuyake kddiweb';

$text = "\xF7\x87";
Encode::from_to($text, 'x-sjis-e4u-softbank3g', 'x-utf8-e4u-docomo', FB_EMOJI_TEXT());
is $text, '[夕焼け]', 'yuyake softbank3g';

$text = "\xF9\xE9";
Encode::from_to($text, 'x-sjis-e4u-docomo', 'x-utf8-e4u-softbank3g', FB_EMOJI_TEXT());
is $text, '[バナナ]', 'banana docomo';
$text = "\xF3\xF6";
Encode::from_to($text, 'x-sjis-e4u-kddiweb', 'x-utf8-e4u-softbank3g', FB_EMOJI_TEXT());
is $text, '[バナナ]', 'banana kddiweb';

$text = "\xF9\x56";
Encode::from_to($text, 'x-sjis-e4u-docomo', 'x-utf8-e4u-kddiweb', FB_EMOJI_TEXT());
is $text, '[いす]', 'seat docomo';
$text = "\xF7\x5F";
Encode::from_to($text, 'x-sjis-e4u-softbank3g', 'x-utf8-e4u-kddiweb', FB_EMOJI_TEXT());
is $text, '[いす]', 'seat softbank3g';

# fallback to docomo

$text = "\xF8\x9F";
Encode::from_to($text, 'x-sjis-emoji-docomo', 'x-utf8-emoji-none', FB_EMOJI_TEXT());
is $text, '[晴れ]', 'sun docomo';
$text = "\xF6\x60";
Encode::from_to($text, 'x-sjis-emoji-kddiweb', 'x-utf8-emoji-none', FB_EMOJI_TEXT());
is $text, '[晴れ]', 'sun kddiweb';
$text = "\xF9\x8B";
Encode::from_to($text, 'x-sjis-emoji-softbank3g', 'x-utf8-emoji-none', FB_EMOJI_TEXT());
is $text, '[晴れ]', 'sun softbank3g';

$text = "\xF9\x7D";
Encode::from_to($text, 'x-sjis-emoji-docomo', 'x-utf8-emoji-none', FB_EMOJI_TEXT());
is $text, '[パスワード]', 'key docomo';
$text = "\xF6\xF2";
Encode::from_to($text, 'x-sjis-emoji-kddiweb', 'x-utf8-emoji-none', FB_EMOJI_TEXT());
is $text, '[パスワード]', 'key kddiweb';
$text = "\xF9\x80";
Encode::from_to($text, 'x-sjis-emoji-softbank3g', 'x-utf8-emoji-none', FB_EMOJI_TEXT());
is $text, '[パスワード]', 'key softbank3g';

# Ｔｈｉｓ　ｆｉｌｅ　ｗａｓ　ｗｒｉｔｔｅｎ　ｉｎ　ＵＴＦ－８
