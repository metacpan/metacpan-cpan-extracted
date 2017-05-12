#!/usr/bin/env perl -w

# $Id: t3.t 7 2009-09-16 15:41:34Z stro $

use strict;
use warnings;
use Test;

BEGIN { plan tests => 2 }

use Lingua::Cyrillic::Translit::ICAO;

ok(Lingua::Cyrillic::Translit::ICAO::cyr2icao('пиво', 'uk', 'cp866'), 'pyvo');
ok(Lingua::Cyrillic::Translit::ICAO::cyr2icao('Трушель', 'uk', 'cp866'), 'Trushel');

exit;
