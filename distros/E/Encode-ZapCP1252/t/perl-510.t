#!/usr/bin/perl -w

use strict;
use Test::More;

BEGIN {
    plan skip_all => 'Prototype _ not supported before Perl 5.10'
        if $] < 5.010000;
    plan tests => 7;
}

BEGIN { use_ok 'Encode::ZapCP1252' or die; }

my $cp1252 = join ' ', map { chr } 0x80, 0x82 .. 0x8c, 0x8e, 0x91 .. 0x9c, 0x9e, 0x9f;
my $ascii  = q{e , f ,, ... + ++ ^ % S < OE Z ' ' " " * - -- ~ (tm) s > oe z Y};
my $utf8   = q{€ , ƒ „ … † ‡ ˆ ‰ Š ‹ Œ Ž ‘ ’ “ ” • – — ˜ ™ š › œ ž Ÿ};

# Test conversion of $_.
local $_ = $cp1252;
zap_cp1252;
is $_, $ascii, 'Should have zapped $_ in-place';
local $_ = $cp1252;
fix_cp1252;
is $_, $utf8, 'Should have fixed $_ in-place';

# Test non-in-place conversion of $_.
local $_ = $cp1252;
is zap_cp1252, $ascii, 'Should have $_-zapped return value';
is $_, $cp1252, 'Should not have zapped $_ in-place';

local $_ = $cp1252;
is fix_cp1252, $utf8, 'Should have $_->fixed return value';
is $_, $cp1252, 'Should not have fixed $_ in-place';
