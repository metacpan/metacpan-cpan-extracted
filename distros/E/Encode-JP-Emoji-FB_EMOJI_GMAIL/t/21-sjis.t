use strict;
use warnings;
use lib 't';
use Test::More;
use EncodeUpdate;
use Encode;
use Encode::JP::Emoji;
use Encode::JP::Emoji::FB_EMOJI_GMAIL;

plan tests => 12;

my $text;

$text = "\xF8\x9F";
Encode::from_to($text, 'x-sjis-emoji-docomo', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());
like $text, qr[/mail/e/docomo_ne_jp/000], 'SUN docomo';
$text = "\xF6\x60";
Encode::from_to($text, 'x-sjis-emoji-kddiweb', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());
like $text, qr[/mail/e/ezweb_ne_jp/000], 'SUN kddiweb';
$text = "\xF9\x8B";
Encode::from_to($text, 'x-sjis-emoji-softbank3g', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());
like $text, qr[/mail/e/softbank_ne_jp/000], 'SUN softbank3g';

$text = "\xF9\x7D";
Encode::from_to($text, 'x-sjis-emoji-docomo', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());
like $text, qr[/mail/e/docomo_ne_jp/B82], 'KEY docomo';
$text = "\xF6\xF2";
Encode::from_to($text, 'x-sjis-emoji-kddiweb', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());
like $text, qr[/mail/e/ezweb_ne_jp/B82], 'KEY kddiweb';
$text = "\xF9\x80";
Encode::from_to($text, 'x-sjis-emoji-softbank3g', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());
like $text, qr[/mail/e/softbank_ne_jp/B82], 'KEY softbank3g';

$text = "\xF9\xAD";
Encode::from_to($text, 'x-sjis-emoji-docomo', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());
like $text, qr[/mail/e/docomo_ne_jp/B5D], 'DASH docomo';
$text = "\xF6\xCD";
Encode::from_to($text, 'x-sjis-emoji-kddiweb', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());
like $text, qr[/mail/e/ezweb_ne_jp/B5D], 'DASH kddiweb';
$text = "\xF9\xD0";
Encode::from_to($text, 'x-sjis-emoji-softbank3g', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());
like $text, qr[/mail/e/softbank_ne_jp/B5D], 'DASH softbank3g';

$text = "\xF9\xD9";
Encode::from_to($text, 'x-sjis-emoji-docomo', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());
like $text, qr[/mail/e/docomo_ne_jp/B2B], 'SECRET docomo';
$text = "\xF6\xCA";
Encode::from_to($text, 'x-sjis-emoji-kddiweb', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());
like $text, qr[/mail/e/ezweb_ne_jp/B2B], 'SECRET kddiweb';
$text = "\xF9\xB5";
Encode::from_to($text, 'x-sjis-emoji-softbank3g', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());
like $text, qr[/mail/e/softbank_ne_jp/B2B], 'SECRET softbank3g';
