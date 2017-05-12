#!perl -T

use 5.010;
use strict;
use warnings;

use Test::More tests => 6;
use charnames ':full';

use lib './t/lib';
use CheckItaTrans qw(start_log check_ita_tr);

start_log(__FILE__);

# TEST
check_ita_tr(
    ['Vocca'],
    "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER QOF}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'Vocca',
);

# TEST
check_ita_tr(
    ['Carovigno'],
    "\N{HEBREW LETTER QOF}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER BET}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER NUN}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Carovigno',
);

# TEST
check_ita_tr(
    ['Mantova'],
    "\N{HEBREW LETTER MEM}"
        . "\N{HEBREW POINT PATAH}"
        . "\N{HEBREW LETTER NUN}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER TET}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER BET}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'Mantova',
);

# TEST
check_ita_tr(
    ['Suvereto'],
    "\N{HEBREW LETTER SAMEKH}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER BET}"
        . "\N{HEBREW POINT SEGOL}"    # XXX Should be tsere
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER TET}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Suvereto',
);

# TEST
check_ita_tr(
    ['Fornovo'],
    "\N{HEBREW LETTER PE}"
        . "\N{HEBREW POINT RAFE}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER NUN}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER BET}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Fornovo',
);

# TEST
check_ita_tr(
    ['Pavullo'],
    "\N{HEBREW LETTER PE}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER BET}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER LAMED}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Pavullo',
);
