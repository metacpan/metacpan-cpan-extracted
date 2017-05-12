use strict;
use warnings;
use lib 't';
use Test::More;
use EncodeUpdate;
no utf8;

plan tests => 4;

# ------------------------------------------------------------------------
    use Encode;
    use Encode::JP::Emoji;
    use Encode::JP::Emoji::FB_EMOJI_TEXT;

    # DoCoMo Shift_JIS <SJIS+F95B> octets fallback to "[SOON]"
    my $soon = "\xF9\x5B";
    Encode::from_to($soon, 'x-sjis-e4u-docomo', 'x-sjis-e4u-kddiweb', FB_EMOJI_TEXT());

    # KDDI Shift_JIS <SJIS+F7B5> octets fallback to "[霧]"
    my $fog = "\xF7\xB5";
    Encode::from_to($fog, 'x-sjis-e4u-kddiweb', 'x-sjis-e4u-softbank3g', FB_EMOJI_TEXT());

    # SoftBank UTF-8 <U+E524> string fallback to "[ハムスター]"
    my $hamster = "\x{E524}";
    my $softbank = Encode::encode('x-sjis-e4u-none', $hamster, FB_EMOJI_TEXT());

    # Google UTF-8 <U+FE1C1> octets fallback to "[クマ]"
    my $bear = "\xF3\xBE\x87\x81";
    my $google = Encode::decode('x-utf8-e4u-none', $bear, FB_EMOJI_TEXT());
# ------------------------------------------------------------------------

my $exp1 = encode Shift_JIS => decode_utf8 '[SOON]';
my $exp2 = encode Shift_JIS => decode_utf8 '[霧]';
my $exp3 = encode Shift_JIS => decode_utf8 '[ハムスター]';
my $exp4 = '[クマ]';

is($soon, $exp1, 'soon - docomo sjis - sjis');
is($fog, $exp2, 'fog - kddi utf8 - utf8');
is($softbank, $exp3, 'hamster - softbank utf8 - sjis');
is(encode_utf8($google), $exp4, 'bear - google utf8 - utf8');

# Ｔｈｉｓ　ｆｉｌｅ　ｗａｓ　ｗｒｉｔｔｅｎ　ｉｎ　ＵＴＦ－８
