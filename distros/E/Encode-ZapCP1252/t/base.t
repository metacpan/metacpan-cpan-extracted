#!/usr/bin/perl -w

use strict;
use Test::More tests => 13;

BEGIN { use_ok 'Encode::ZapCP1252' or die; }

can_ok 'Encode::ZapCP1252', 'zap_cp1252';
can_ok __PACKAGE__, 'zap_cp1252';

my $cp1252 = join ' ', map { chr } 0x80, 0x82 .. 0x8c, 0x8e, 0x91 .. 0x9c, 0x9e, 0x9f;
my $ascii  = q{e , f ,, ... + ++ ^ % S < OE Z ' ' " " * - -- ~ (tm) s > oe z Y};
my $utf8   = q{€ , ƒ „ … † ‡ ˆ ‰ Š ‹ Œ Ž ‘ ’ “ ” • – — ˜ ™ š › œ ž Ÿ};

# Test conversion to ASCII.
my $fix_me = $cp1252;
zap_cp1252 $fix_me;
is $fix_me, $ascii, 'Convert to ascii';

# Test conversion to UTF-8.
$fix_me = $cp1252;
fix_cp1252 $fix_me;
is $fix_me, $utf8, 'Convert to utf-8';

# Try checking the return value, too.
$fix_me = $cp1252;
is fix_cp1252 $fix_me, $utf8, 'Check fixed return value';
is $fix_me, $cp1252, 'Should not have been fixed in-place';

$fix_me = $cp1252;
is zap_cp1252 $fix_me, $ascii, 'Check zapped return value';
is $fix_me, $cp1252, 'Should not have been zapped in-place';

# Test conversion to ASCII with modified table.
$Encode::ZapCP1252::ascii_for{"\x80"} = 'E';
$ascii =~ s/^e/E/;
$fix_me = $cp1252;
zap_cp1252 $fix_me;
is $fix_me, $ascii, 'Convert to ascii with modified table';

# Test conversion to UTF-8 with modified table.
$Encode::ZapCP1252::utf8_for{"\x80"} = 'E';
$utf8 =~ s/€/E/;
$fix_me = $cp1252;
fix_cp1252 $fix_me;
is $fix_me, $utf8, 'Convert to utf-8 with modified table';

# Test that undefs are ignored.
is zap_cp1252 undef, undef, 'zap_cp1252 should ignore undef';
is fix_cp1252 undef, undef, 'fix_cp1252 should ignore undef';
