#!/usr/bin/perl -w

use strict;
use Test::More;

BEGIN {
    plan skip_all => 'These tests require Perl 5.8.8 or higher'
        unless $] >= 5.008_008;
    plan tests => 6;
}

BEGIN { use_ok 'Encode::ZapCP1252' or die; }

use utf8;
my $ascii = q{e , f ,, ... + ++ ^ % S < OE Z ' ' " " * - -- ~ (tm) s > oe z Y};
my $utf8  = q{€ , ƒ „ … † ‡ ˆ ‰ Š ‹ Œ Ž ‘ ’ “ ” • – — ˜ ™ š › œ ž Ÿ};

# Test conversion of decoded from ISO-8859-1.
my $fix_me = Encode::decode(
    'ISO-8859-1',
    join ' ', map { chr } 0x80, 0x82 .. 0x8c, 0x8e, 0x91 .. 0x9c, 0x9e, 0x9f
);

fix_cp1252 $fix_me;
is $fix_me, $utf8, 'Convert decoded from Latin-1 to utf-8';

# Try ascii.
$fix_me = Encode::decode(
    'ISO-8859-1',
    join ' ', map { chr } 0x80, 0x82 .. 0x8c, 0x8e, 0x91 .. 0x9c, 0x9e, 0x9f
);
zap_cp1252 $fix_me;
is $fix_me, $ascii, 'Convert decoded from Latin-1 to ascii';

# Test conversion with utf8 bit flipped.
$fix_me = join ' ', map { chr } 0x80, 0x82 .. 0x8c, 0x8e, 0x91 .. 0x9c, 0x9e, 0x9f;
Encode::_utf8_on($fix_me);
fix_cp1252 $fix_me;
is $fix_me, $utf8, 'Convert utf8-bit-flipped to utf-8';

# Try it with ascii.
$fix_me = join ' ', map { chr } 0x80, 0x82 .. 0x8c, 0x8e, 0x91 .. 0x9c, 0x9e, 0x9f;
Encode::_utf8_on($fix_me);
zap_cp1252 $fix_me;
is $fix_me, $ascii, 'Convert utf8-bit-flipped to ascii';

# Test conversion to decoded with modified table.
$Encode::ZapCP1252::utf8_for{"\x80"} = 'E';
$utf8 =~ s/€/E/;

$fix_me = Encode::decode(
    'ISO-8859-1',
    join ' ', map { chr } 0x80, 0x82 .. 0x8c, 0x8e, 0x91 .. 0x9c, 0x9e, 0x9f
);

fix_cp1252 $fix_me;
is $fix_me, $utf8, 'Convert decoded from Latin-1 with modified table';


