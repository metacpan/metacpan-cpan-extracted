use strict;
use warnings;
use lib 't';
require 'test-util.pl';
use Test::More;
use Encode;
use Encode::JP::Emoji;

plan tests => 24;

{
    my $sjis_docomo   = pack 'H*', 'F940';
    my $sjis_kddi     = pack 'H*', 'F767';
    my $sjis_softbank = pack 'H*', 'F7BA';
    my $strg_docomo   = chr hex 'E69C';
    my $strg_kddi     = chr hex 'E54B';
    my $strg_softbank = chr hex 'E21A';
    my $goog_docomo   = chr hex 'FE011';
    my $goog_kddi     = chr hex 'FEB64';
    my $goog_softbank = chr hex 'FEB64';
    my $utf8_docomo   = encode 'utf8' => $strg_docomo;
    my $utf8_kddi     = encode 'utf8' => $strg_kddi;
    my $utf8_softbank = encode 'utf8' => $strg_softbank;

    is(ohex($sjis_docomo),   '\xF9\x40',  'octets docomo sjis');
    is(ohex($sjis_kddi),     '\xF7\x67',  'octets kddiapp sjis');
    is(ohex($sjis_softbank), '\xF7\xBA',  'octets softbank3g sjis');
    is(shex($goog_docomo),    '\x{FE011}', 'string docomo google utf8');
    is(shex($goog_kddi),      '\x{FEB64}', 'string kddiapp google utf8');
    is(shex($goog_softbank),  '\x{FEB64}', 'string softbank3g google utf8');

    is(ohex(encode('x-sjis-emoji-docomo-pp', $strg_docomo)), ohex($sjis_docomo), 'encode docomo sjis - docomo utf8');
    is(shex(decode('x-sjis-emoji-docomo-pp', $sjis_docomo)), shex($strg_docomo), 'decode docomo sjis - docomo utf8');
    is(ohex(encode('x-sjis-e4u-docomo-pp', $goog_docomo)), ohex($sjis_docomo), 'encode docomo sjis - google utf8');
    is(shex(decode('x-sjis-e4u-docomo-pp', $sjis_docomo)), shex($goog_docomo), 'decode docomo sjis - google utf8');
    is(ohex(encode('x-utf8-e4u-docomo-pp', $goog_docomo)), ohex($utf8_docomo), 'encode docomo utf8 - google utf8');
    is(shex(decode('x-utf8-e4u-docomo-pp', $utf8_docomo)), shex($goog_docomo), 'decode docomo utf8 - google utf8');

    is(ohex(encode('x-sjis-emoji-kddiapp-pp', $strg_kddi)), ohex($sjis_kddi), 'encode kddiapp sjis - kddiapp utf8');
    is(shex(decode('x-sjis-emoji-kddiapp-pp', $sjis_kddi)), shex($strg_kddi), 'decode kddiapp sjis - kddiapp utf8');
    is(ohex(encode('x-sjis-e4u-kddiapp-pp', $goog_kddi)), ohex($sjis_kddi), 'encode kddiapp sjis - google utf8');
    is(shex(decode('x-sjis-e4u-kddiapp-pp', $sjis_kddi)), shex($goog_kddi), 'decode kddiapp sjis - google utf8');
    is(ohex(encode('x-utf8-e4u-kddiapp-pp', $goog_kddi)), ohex($utf8_kddi), 'encode kddiapp utf8 - google utf8');
    is(shex(decode('x-utf8-e4u-kddiapp-pp', $utf8_kddi)), shex($goog_kddi), 'decode kddiapp utf8 - google utf8');

    is(ohex(encode('x-sjis-emoji-softbank3g-pp', $strg_softbank)), ohex($sjis_softbank), 'encode softbank3g sjis - softbank3g utf8');
    is(shex(decode('x-sjis-emoji-softbank3g-pp', $sjis_softbank)), shex($strg_softbank), 'decode softbank3g sjis - softbank3g utf8');
    is(ohex(encode('x-sjis-e4u-softbank3g-pp', $goog_softbank)), ohex($sjis_softbank), 'encode softbank3g sjis - google utf8');
    is(shex(decode('x-sjis-e4u-softbank3g-pp', $sjis_softbank)), shex($goog_softbank), 'decode softbank3g sjis - google utf8');
    is(ohex(encode('x-utf8-e4u-softbank3g-pp', $goog_softbank)), ohex($utf8_softbank), 'encode softbank3g utf8 - google utf8');
    is(shex(decode('x-utf8-e4u-softbank3g-pp', $utf8_softbank)), shex($goog_softbank), 'decode softbank3g utf8 - google utf8');
}
