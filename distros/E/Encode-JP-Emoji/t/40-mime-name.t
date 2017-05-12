use strict;
use warnings;
use lib 't';
use Test::More;
use Encode::JP::Emoji;

my @encodings = qw(
    x-sjis-emoji-docomo-pp          x-sjis-emoji-docomo
    x-sjis-emoji-kddiapp-pp         x-sjis-emoji-kddiapp
    x-sjis-emoji-kddiweb-pp         x-sjis-emoji-kddiweb
    x-sjis-emoji-softbank2g-pp      x-sjis-emoji-softbank2g
    x-sjis-emoji-softbank3g-pp      x-sjis-emoji-softbank3g
    x-utf8-emoji-docomo-pp          x-utf8-emoji-docomo
    x-utf8-emoji-kddiapp-pp         x-utf8-emoji-kddiapp
    x-utf8-emoji-kddiweb-pp         x-utf8-emoji-kddiweb
    x-utf8-emoji-softbank2g-pp      x-utf8-emoji-softbank2g
    x-utf8-emoji-softbank3g-pp      x-utf8-emoji-softbank3g
    x-sjis-e4u-docomo-pp            x-sjis-e4u-docomo
    x-sjis-e4u-kddiapp-pp           x-sjis-e4u-kddiapp
    x-sjis-e4u-kddiweb-pp           x-sjis-e4u-kddiweb
    x-sjis-e4u-softbank2g-pp        x-sjis-e4u-softbank2g
    x-sjis-e4u-softbank3g-pp        x-sjis-e4u-softbank3g
    x-utf8-e4u-docomo-pp            x-utf8-e4u-docomo
    x-utf8-e4u-kddiapp-pp           x-utf8-e4u-kddiapp
    x-utf8-e4u-kddiweb-pp           x-utf8-e4u-kddiweb
    x-utf8-e4u-softbank2g-pp        x-utf8-e4u-softbank2g
    x-utf8-e4u-softbank3g-pp        x-utf8-e4u-softbank3g
    x-utf8-e4u-mixed-pp             x-utf8-e4u-mixed
    x-utf8-e4u-google-pp            x-utf8-e4u-google
    x-utf8-e4u-unicode-pp           x-utf8-e4u-unicode
    x-sjis-emoji-none-pp            x-sjis-emoji-none
    x-utf8-emoji-none-pp            x-utf8-emoji-none
    x-sjis-e4u-none-pp              x-sjis-e4u-none
    x-utf8-e4u-none-pp              x-utf8-e4u-none
);

plan tests => 2 * @encodings;

for my $name (@encodings) {
	my $base = ($name =~ /^x-sjis-/ ? 'Shift_JIS' : 'UTF-8');
    my $encoding = Encode::find_encoding($name);
    ok $encoding, "$name find_encoding";
    is $encoding->mime_name, $base, "$name mime_name $base";
}
