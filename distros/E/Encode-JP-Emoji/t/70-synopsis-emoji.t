use strict;
use warnings;
use lib 't';
require 'test-util.pl';
use Test::More;

plan tests => 5;

# ------------------------------------------------------------------------
    use Encode;
    use Encode::JP::Emoji;

    # DoCoMo Shift_JIS <SJIS+F89F> octets to DoCoMo UTF-8 <U+E63E> octets
    my $sun = "\xF8\x9F";
    Encode::from_to($sun, 'x-sjis-emoji-docomo', 'utf8');

    # KDDI Shift_JIS <SJIS+F7F5> octets to SoftBank Shift_JIS <SJIS+F747> octets
    my $scream = "\xF7\xF5";
    Encode::from_to($scream, 'x-sjis-e4u-kddiapp', 'x-sjis-e4u-softbank3g');

    # DoCoMo UTF-8 <U+E6E2> octets to Google UTF-8 <U+FE82E> octets
    my $keycap1 = "\xEE\x9B\xA2";
    Encode::from_to($keycap1, 'x-utf8-e4u-docomo', 'utf8');

    # Google UTF-8 <U+FE001> string to KDDI Shift_JIS <SJIS+F7C5> octets
    my $newmoon = "\x{FE011}";
    my $kddi = Encode::encode('x-sjis-e4u-kddiweb', $newmoon);

    # SoftBank Shift_JIS <SJIS+F750> octets to SoftBank UTF-8 <U+E110> string
    my $clover = "\xF7\x50";
    my $softbank = Encode::decode('x-sjis-emoji-softbank3g', $clover);
# ------------------------------------------------------------------------

is ohex($sun), '\xEE\x98\xBE', 'sun - docomo sjis to docomo utf8';
is ohex($scream), '\xF7\x47', 'scream - kddi sjis to softbank sjis';
is ohex($keycap1), '\xF3\xBE\xA0\xAE', 'keycap1 - docomo utf8 to google utf8';
is ohex($kddi), '\xF7\xC5', 'newmoon - google utf8 to kddi sjis';
is shex($softbank), '\x{E110}', 'clover - softbank sjis to softbank utf8';
