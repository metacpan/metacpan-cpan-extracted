use strict;
use warnings;
use lib 't';
use Test::More;
use EncodeUpdate;
use Encode;
use Encode::JP::Emoji;
use Encode::JP::Emoji::FB_EMOJI_TYPECAST;

plan tests => 12;

my $text;

$text = "\xF8\x9F";
Encode::from_to($text, 'x-sjis-emoji-docomo', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());
like $text, qr[sun.gif], 'SUN docomo';
$text = "\xF6\x60";
Encode::from_to($text, 'x-sjis-emoji-kddiweb', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());
like $text, qr[sun.gif], 'SUN kddiweb';
$text = "\xF9\x8B";
Encode::from_to($text, 'x-sjis-emoji-softbank3g', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());
like $text, qr[sun.gif], 'SUN softbank3g';

$text = "\xF9\x7D";
Encode::from_to($text, 'x-sjis-emoji-docomo', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());
like $text, qr[key.gif], 'KEY docomo';
$text = "\xF6\xF2";
Encode::from_to($text, 'x-sjis-emoji-kddiweb', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());
like $text, qr[key.gif], 'KEY kddiweb';
$text = "\xF9\x80";
Encode::from_to($text, 'x-sjis-emoji-softbank3g', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());
like $text, qr[key.gif], 'KEY softbank3g';

$text = "\xF9\xAD";
Encode::from_to($text, 'x-sjis-emoji-docomo', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());
like $text, qr[dash.gif], 'DASH docomo';
$text = "\xF6\xCD";
Encode::from_to($text, 'x-sjis-emoji-kddiweb', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());
like $text, qr[dash.gif], 'DASH kddiweb';
$text = "\xF9\xD0";
Encode::from_to($text, 'x-sjis-emoji-softbank3g', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());
like $text, qr[dash.gif], 'DASH softbank3g';

$text = "\xF9\xD9";
Encode::from_to($text, 'x-sjis-emoji-docomo', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());
like $text, qr[secret.gif], 'SECRET docomo';
$text = "\xF6\xCA";
Encode::from_to($text, 'x-sjis-emoji-kddiweb', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());
like $text, qr[secret.gif], 'SECRET kddiweb';
$text = "\xF9\xB5";
Encode::from_to($text, 'x-sjis-emoji-softbank3g', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());
like $text, qr[secret.gif], 'SECRET softbank3g';
