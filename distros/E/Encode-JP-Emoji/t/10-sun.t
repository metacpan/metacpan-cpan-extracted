use strict;
use warnings;
use lib 't';
require 'test-util.pl';
use Test::More;
use Encode;
use Encode::JP::Emoji;

plan tests => 22;

{
    my $sjis_docomo   = pack 'H*', 'F89F';
    my $sjis_kddi     = pack 'H*', 'F660';
    my $sjis_softbank = pack 'H*', 'F98B';
    my $strg_docomo   = chr hex 'E63E';
    my $strg_kddi     = chr hex 'E488';
    my $strg_softbank = chr hex 'E04A';
    my $strg_google   = chr hex 'FE000';
    my $utf8_docomo   = encode 'utf8' => $strg_docomo;
    my $utf8_kddi     = encode 'utf8' => $strg_kddi;
    my $utf8_softbank = encode 'utf8' => $strg_softbank;

    is(ohex($sjis_docomo),   '\xF8\x9F',  'octets docomo sjis');
    is(ohex($sjis_kddi),     '\xF6\x60',  'octets kddiapp sjis');
    is(ohex($sjis_softbank), '\xF9\x8B',  'octets softbank3g sjis');
    is(shex($strg_google),   '\x{FE000}', 'string google utf8');

    is(ohex(encode('x-sjis-emoji-docomo-pp', $strg_docomo)), ohex($sjis_docomo), 'encode docomo sjis - docomo utf8');
    is(shex(decode('x-sjis-emoji-docomo-pp', $sjis_docomo)), shex($strg_docomo), 'decode docomo sjis - docomo utf8');
    is(ohex(encode('x-sjis-e4u-docomo-pp', $strg_google)), ohex($sjis_docomo), 'encode docomo sjis - google utf8');
    is(shex(decode('x-sjis-e4u-docomo-pp', $sjis_docomo)), shex($strg_google), 'decode docomo sjis - google utf8');
    is(ohex(encode('x-utf8-e4u-docomo-pp', $strg_google)), ohex($utf8_docomo), 'encode docomo utf8 - google utf8');
    is(shex(decode('x-utf8-e4u-docomo-pp', $utf8_docomo)), shex($strg_google), 'decode docomo utf8 - google utf8');

    is(ohex(encode('x-sjis-emoji-kddiapp-pp', $strg_kddi)), ohex($sjis_kddi), 'encode kddiapp sjis - kddiapp utf8');
    is(shex(decode('x-sjis-emoji-kddiapp-pp', $sjis_kddi)), shex($strg_kddi), 'decode kddiapp sjis - kddiapp utf8');
    is(ohex(encode('x-sjis-e4u-kddiapp-pp', $strg_google)), ohex($sjis_kddi), 'encode kddiapp sjis - google utf8');
    is(shex(decode('x-sjis-e4u-kddiapp-pp', $sjis_kddi)), shex($strg_google), 'decode kddiapp sjis - google utf8');
    is(ohex(encode('x-utf8-e4u-kddiapp-pp', $strg_google)), ohex($utf8_kddi), 'encode kddiapp utf8 - google utf8');
    is(shex(decode('x-utf8-e4u-kddiapp-pp', $utf8_kddi)), shex($strg_google), 'decode kddiapp utf8 - google utf8');

    is(ohex(encode('x-sjis-emoji-softbank3g-pp', $strg_softbank)), ohex($sjis_softbank), 'encode softbank3g sjis - softbank3g utf8');
    is(shex(decode('x-sjis-emoji-softbank3g-pp', $sjis_softbank)), shex($strg_softbank), 'decode softbank3g sjis - softbank3g utf8');
    is(ohex(encode('x-sjis-e4u-softbank3g-pp', $strg_google)), ohex($sjis_softbank), 'encode softbank3g sjis - google utf8');
    is(shex(decode('x-sjis-e4u-softbank3g-pp', $sjis_softbank)), shex($strg_google), 'decode softbank3g sjis - google utf8');
    is(ohex(encode('x-utf8-e4u-softbank3g-pp', $strg_google)), ohex($utf8_softbank), 'encode softbank3g utf8 - google utf8');
    is(shex(decode('x-utf8-e4u-softbank3g-pp', $utf8_softbank)), shex($strg_google), 'decode softbank3g utf8 - google utf8');
}
