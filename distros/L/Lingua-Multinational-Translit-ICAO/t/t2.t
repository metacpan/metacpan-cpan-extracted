#!/usr/bin/env perl -w

# $Id: t2.t 6 2009-09-16 15:37:46Z stro $

use strict;
use warnings;
use Test;

BEGIN { plan tests => 5 }

use Lingua::Multinational::Translit::ICAO;

ok(Lingua::Multinational::Translit::ICAO::ml2icao('Œthel'), 'OEthel');
ok(Lingua::Multinational::Translit::ICAO::ml2icao('æon'), 'aeon');
ok(Lingua::Multinational::Translit::ICAO::ml2icao('qwerty'), 'qwerty');
ok(Lingua::Multinational::Translit::ICAO::ml2icao('phœnix'), 'phoenix');
ok(Lingua::Multinational::Translit::ICAO::ml2icao('Gæa'), 'Gaea');


exit;
