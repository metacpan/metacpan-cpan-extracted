#!/usr/bin/env perl -w

# $Id: t2.t 7 2009-09-16 15:41:34Z stro $

use strict;
use warnings;
use Test;

BEGIN { plan tests => 4 }

use Lingua::Cyrillic::Translit::ICAO;

ok(Lingua::Cyrillic::Translit::ICAO::cyr2icao('йцукен', 'ru', 'cp866'), 'itsuken');
ok(Lingua::Cyrillic::Translit::ICAO::cyr2icao('пароль', 'ru', 'cp866'), 'parol');
ok(Lingua::Cyrillic::Translit::ICAO::cyr2icao('qwerty', 'ru', 'cp866'), 'qwerty');
ok(Lingua::Cyrillic::Translit::ICAO::cyr2icao('Трушель', 'ru', 'cp866'), 'Trushel');

exit;
