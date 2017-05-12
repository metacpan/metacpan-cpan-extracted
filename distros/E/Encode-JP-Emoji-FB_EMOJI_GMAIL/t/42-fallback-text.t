use strict;
use warnings;
use lib 't';
use Test::More;
use EncodeUpdate;
use Encode;
use Encode::JP::Emoji;
use Encode::JP::Emoji::FB_EMOJI_GMAIL;
no utf8;    # utf-8 encoded but not flagged

plan tests => 22;

# utf8

my $text;
$text = encode('x-utf8-e4u-none-pp' => "\x{E644}", FB_EMOJI_GMAIL());
like $text, qr/\Q[霧]\E/, 'fog docomo';
$text = encode('x-utf8-e4u-none-pp' => "\x{FE006}", FB_EMOJI_GMAIL());
like $text, qr/\Q[霧]\E/, 'fog google';

$text = encode('x-utf8-e4u-none-pp' => "\x{E71F}", FB_EMOJI_GMAIL());
like $text, qr/\Q[腕時計]\E/, 'watch docomo';
$text = encode('x-utf8-e4u-none-pp' => "\x{FE01D}", FB_EMOJI_GMAIL());
like $text, qr/\Q[腕時計]\E/, 'watch google';
$text = encode('x-utf8-e4u-none-pp' => "\x{231A}", FB_EMOJI_GMAIL());
like $text, qr/\Q[腕時計]\E/, 'watch unicode';

$text = encode('x-utf8-e4u-none-pp' => "\x{E349}", FB_EMOJI_GMAIL());
like $text, qr/\Q[トマト]\E/, 'tomato softbank3g';
$text = encode('x-utf8-e4u-none-pp' => "\x{FE055}", FB_EMOJI_GMAIL());
like $text, qr/\Q[トマト]\E/, 'tomato google';

$text = encode('x-utf8-e4u-none-pp' => "\x{E037}", FB_EMOJI_GMAIL());
like $text, qr/\Q[教会]\E/, 'church softbank3g';
$text = encode('x-utf8-e4u-none-pp' => "\x{FE4BB}", FB_EMOJI_GMAIL());
like $text, qr/\Q[教会]\E/, 'church google';
$text = encode('x-utf8-e4u-none-pp' => "\x{26EA}", FB_EMOJI_GMAIL());
like $text, qr/\Q[教会]\E/, 'church unicode';

# sjis

$text = "\xF3\x4D";
Encode::from_to($text, 'x-sjis-e4u-kddiweb', 'x-utf8-e4u-docomo', FB_EMOJI_GMAIL());
like $text, qr/\Q[夕焼け]\E/, 'yuyake kddiweb';

$text = "\xF7\x87";
Encode::from_to($text, 'x-sjis-e4u-softbank3g', 'x-utf8-e4u-docomo', FB_EMOJI_GMAIL());
like $text, qr/\Q[夕焼け]\E/, 'yuyake softbank3g';

$text = "\xF9\xE9";
Encode::from_to($text, 'x-sjis-e4u-docomo', 'x-utf8-e4u-softbank3g', FB_EMOJI_GMAIL());
like $text, qr/\Q[バナナ]\E/, 'banana docomo';
$text = "\xF3\xF6";
Encode::from_to($text, 'x-sjis-e4u-kddiweb', 'x-utf8-e4u-softbank3g', FB_EMOJI_GMAIL());
like $text, qr/\Q[バナナ]\E/, 'banana kddiweb';

$text = "\xF9\x56";
Encode::from_to($text, 'x-sjis-e4u-docomo', 'x-utf8-e4u-kddiweb', FB_EMOJI_GMAIL());
like $text, qr/\Q[いす]\E/, 'seat docomo';
$text = "\xF7\x5F";
Encode::from_to($text, 'x-sjis-e4u-softbank3g', 'x-utf8-e4u-kddiweb', FB_EMOJI_GMAIL());
like $text, qr/\Q[いす]\E/, 'seat softbank3g';

# fallback to docomo

$text = "\xF8\x9F";
Encode::from_to($text, 'x-sjis-emoji-docomo', 'x-utf8-emoji-none', FB_EMOJI_GMAIL());
like $text, qr/\Q[晴れ]\E/, 'sun docomo';
$text = "\xF6\x60";
Encode::from_to($text, 'x-sjis-emoji-kddiweb', 'x-utf8-emoji-none', FB_EMOJI_GMAIL());
like $text, qr/\Q[晴れ]\E/, 'sun kddiweb';
$text = "\xF9\x8B";
Encode::from_to($text, 'x-sjis-emoji-softbank3g', 'x-utf8-emoji-none', FB_EMOJI_GMAIL());
like $text, qr/\Q[晴れ]\E/, 'sun softbank3g';

$text = "\xF9\x7D";
Encode::from_to($text, 'x-sjis-emoji-docomo', 'x-utf8-emoji-none', FB_EMOJI_GMAIL());
like $text, qr/\Q[パスワード]\E/, 'key docomo';
$text = "\xF6\xF2";
Encode::from_to($text, 'x-sjis-emoji-kddiweb', 'x-utf8-emoji-none', FB_EMOJI_GMAIL());
like $text, qr/\Q[パスワード]\E/, 'key kddiweb';
$text = "\xF9\x80";
Encode::from_to($text, 'x-sjis-emoji-softbank3g', 'x-utf8-emoji-none', FB_EMOJI_GMAIL());
like $text, qr/\Q[パスワード]\E/, 'key softbank3g';

# Ｔｈｉｓ　ｆｉｌｅ　ｗａｓ　ｗｒｉｔｔｅｎ　ｉｎ　ＵＴＦ－８
