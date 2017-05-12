use strict;
use warnings;
use lib 't';
use Test::More;
use EncodeUpdate;

plan tests => 8;

# ------------------------------------------------------------------------
    use Encode;
    use Encode::JP::Emoji;
    use Encode::JP::Emoji::FB_EMOJI_TYPECAST;

    my $image_base = 'http://example.com/images/emoticons/';
    $Encode::JP::Emoji::FB_EMOJI_TYPECAST::IMAGE_BASE = $image_base;

    # DoCoMo Shift_JIS <SJIS+F89F> octets
    # <img src="http://example.com/images/emoticons/sun.gif" alt="[晴れ]" class="e" />
    my $sun = "\xF8\x9F";
    Encode::from_to($sun, 'x-sjis-emoji-docomo', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());

    # KDDI(web) Shift_JIS <SJIS+F3A5> octets
    # <img src="http://example.com/images/emoticons/kissmark.gif" alt="[口]" class="e" />
    my $mouse = "\xF3\xA5";
    Encode::from_to($mouse, 'x-sjis-emoji-kddiweb', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());

    # SoftBank UTF-8 <U+E20C> string
    # <img src="http://example.com/images/emoticons/heart.gif" alt="[ハート]" class="e" />
    my $heart = "\x{E20C}";
    $heart = Encode::encode('x-sjis-e4u-none', $heart, FB_EMOJI_TYPECAST());

    # Google UTF-8 <U+FE983> octets
    # <img src="http://example.com/images/emoticons/beer.gif" alt="[ビール]" class="e" />
    my $beer = "\xF3\xBE\xA6\x83";
    $beer = Encode::decode('x-utf8-e4u-none', $beer, FB_EMOJI_TYPECAST());
# ------------------------------------------------------------------------

like $sun,   qr[$image_base], 'sun image_base';
like $mouse, qr[$image_base], 'mouse image_base';
like $heart, qr[$image_base], 'heart image_base';
like $beer,  qr[$image_base], 'beer image_base';

like $sun,   qr[sun.gif],      'sun from_to';
like $mouse, qr[kissmark.gif], 'mouse from_to';
like $heart, qr[heart.gif],    'heart encode';
like $beer,  qr[beer.gif],     'beer decode';

# print $sun, "\n";
# print $mouse, "\n";
# print $heart, "\n";
# print $beer, "\n";

# Ｔｈｉｓ　ｆｉｌｅ　ｗａｓ　ｗｒｉｔｔｅｎ　ｉｎ　ＵＴＦ－８
