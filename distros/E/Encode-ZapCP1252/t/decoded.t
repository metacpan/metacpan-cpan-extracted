#!/usr/bin/perl -w

use strict;
use Test::More;

BEGIN {
    plan skip_all => 'These tests require Perl 5.8.8 or higher'
        unless $] >= 5.008_008;
    plan tests => 10;
}

BEGIN { use_ok 'Encode::ZapCP1252' or die; }

use utf8;
my $ascii = q{e , f ,, ... + ++ ^ % S < OE Z ' ' " " * - -- ~ (tm) s > oe z Y};
my $utf8  = q{€ , ƒ „ … † ‡ ˆ ‰ Š ‹ Œ Ž ‘ ’ “ ” • – — ˜ ™ š › œ ž Ÿ};

# Test conversion of text decoded from ISO-8859-1.
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
my $euro = $Encode::ZapCP1252::utf8_for{"\x80"};
$Encode::ZapCP1252::utf8_for{"\x80"} = 'E';
$utf8 =~ s/€/E/;

$fix_me = Encode::decode(
    'ISO-8859-1',
    join ' ', map { chr } 0x80, 0x82 .. 0x8c, 0x8e, 0x91 .. 0x9c, 0x9e, 0x9f
);

fix_cp1252 $fix_me;
is $fix_me, $utf8, 'Convert decoded from Latin-1 with modified table';

# Test it with the valid use of one of the gremlins (π is [0xcf,0x80]) in UTF-8.
is fix_cp1252 'π', 'π', 'Should not convert valid use of 0x80';
is zap_cp1252 'π', 'π', 'Should not zap valid use of 0x80';

# But it should convert it if it's not UTF-8.
my $utf8_euro = Encode::encode_utf8($euro);
$Encode::ZapCP1252::utf8_for{"\x80"} = $utf8_euro;
is fix_cp1252 "\xCF\x80", "\xCF" . $utf8_euro,
    'Should convert 0x80 when not parsing UTF-8';
is zap_cp1252 "\xCF\x80", qq{\xCF$Encode::ZapCP1252::ascii_for{"\x80"}},
'Should convert 0x80 to ASCII when not parsing UTF-8';
