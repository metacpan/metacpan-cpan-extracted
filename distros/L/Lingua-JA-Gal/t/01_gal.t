use strict;
use warnings;
use utf8;
use Test::More tests => 4;

use Lingua::JA::Gal;

is( Lingua::JA::Gal->gal("ひふほみ"), "ひ,ζ,ﾚまゐ" );
is( Lingua::JA::Gal->gal("ｲｼａ"), "ィｼ＠" );

is( Lingua::JA::Gal->gal("祝祝祝", { rate =>   0 }), "祝祝祝" );
is( Lingua::JA::Gal->gal("祝祝祝", { rate => 100 }), "ネ兄ネ兄ネ兄" );
