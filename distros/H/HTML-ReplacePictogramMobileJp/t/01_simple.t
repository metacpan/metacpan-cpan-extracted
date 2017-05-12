use strict;
use warnings;
use Test::More tests => 18;
use HTML::ReplacePictogramMobileJp;
use Encode;
use Encode::JP::Mobile;

is _x('I', 'utf8', encode('x-utf8-docomo', "\x{E751}")), "<U+E751> I";
is _x('I', 'sjis', encode('x-sjis-docomo', "\x{E757}")), "<U+E757> I";
is _x('I', 'sjis', "&#xE757;"), "<U+E757> I";
is _x('I', 'sjis', "&#63647;"), "<U+E63E> I";

is _x('E', 'utf8', encode('x-utf8-ezweb', "\x{ED80}")), "<U+ED80> E";
is _x('E', 'utf8', "&#xED80;"), "<U+ED80> E", 'kddi-utf8: kddi unicode hex cref';
is _x('E', 'sjis', "&#xF987;"), "<U+EFFB> E", 'kddi-sjis: docomo unicode hex cref';
is _x('E', 'sjis', "&#xED80;"), "<U+ED80> E", 'kddi-sjis: kddi unicode hex cref';
is _x('E', 'sjis', q{<img localsrc="1" />}), "<U+EF59> E", '<img localsrc=".." />';
is _x('E', 'utf8', q{<img localsrc="1" />}), "<U+EF59> E", '<img localsrc=".." />';
# is _x('E', 'sjis', encode('x-sjis-docomo', "\x{E757}")), "<U+E757> I", 'docomo => kddi';
is _x('E', 'sjis', encode('x-sjis-kddi-auto', "\x{ED8D}")), "<U+ED8D> E", 'kddi-auto';

is _x('V', 'sjis', encode('x-sjis-softbank', "\x{E001}")), "<U+E001> V", 'softbank-escape';
is _x('V', 'sjis', "&#xE001;"), "<U+E001> V", 'softbank-unicode-hex-cref-sjis';
is _x('V', 'utf8', encode('x-utf8-softbank', "\x{E537}")), "<U+E537> V", 'softbank-utf8';
is _x('V', 'utf8', "&#xE537;"), "<U+E537> V", 'softbank-utf8-hex-cref';

is _x('H', 'utf8', "&#xE757;"), "<U+E757> I", 'airh utf8 hex cref';
is _x('H', 'sjis', "&#xF8A0;"), "<U+E63F> I", 'airh sjis hex cref';
is _x('H', 'sjis', "\xf9\xfc"), "<U+E757> I", 'airh sjis binary';

sub _x {
    my $carrier = shift;
    my $method = shift;
    my $html_ref = shift;

    HTML::ReplacePictogramMobileJp->replace(
        carrier  => $carrier,
        charset  => $method,
        html     => $html_ref,
        callback => sub {
            my ( $unicode, $carrier ) = @_;
            sprintf "<U+%X> $carrier", $unicode;
        }
    );
}

