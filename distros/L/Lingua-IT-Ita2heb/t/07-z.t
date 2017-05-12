#!perl -T

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use charnames ':full';

use lib './t/lib';
use CheckItaTrans qw(start_log check_ita_tr);

start_log(__FILE__);

# TEST
check_ita_tr(
    ['Melazzo'],
    "\N{HEBREW LETTER MEM}" . "\N{HEBREW POINT SEGOL}"   # XXX should be tsere
        . "\N{HEBREW LETTER LAMED}"
        . "\N{HEBREW POINT PATAH}"
        . "\N{HEBREW LETTER TSADI}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Melazzo',
);

# TEST
check_ita_tr(
    ['Zibello'],
    "\N{HEBREW LETTER DALET}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER ZAYIN}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER BET}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER LAMED}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Zibello',
);

