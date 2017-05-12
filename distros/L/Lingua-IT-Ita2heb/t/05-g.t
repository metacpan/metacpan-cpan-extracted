#!perl -T

use 5.010;
use strict;
use warnings;

use Test::More tests => 9;
use Lingua::IT::Ita2heb;
use charnames ':full';

use lib './t/lib';
use CheckItaTrans qw(start_log check_ita_tr);

start_log(__FILE__);

# TEST
check_ita_tr(
    ['Pago'],
    "\N{HEBREW LETTER PE}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER GIMEL}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Pago',
);

# TEST
check_ita_tr(
    ['Giardinello'],
    "\N{HEBREW LETTER GIMEL}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT PATAH}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER DALET}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER NUN}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER LAMED}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Giardinello',
);

# TEST
check_ita_tr(
    ['Ruggiero'],
    "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER GIMEL}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Ruggiero',
);

# TEST
check_ita_tr(
    ['Giorgio'],
    "\N{HEBREW LETTER GIMEL}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER GIMEL}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Giorgio',
);

# TEST
check_ita_tr(
    ['Giussano'],
    "\N{HEBREW LETTER GIMEL}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER SAMEKH}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER NUN}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Giussano',
);

# TEST
check_ita_tr(
    ['Sardegna'],
    "\N{HEBREW LETTER SAMEKH}"
        . "\N{HEBREW POINT PATAH}"
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER DALET}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER NUN}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'Sardegna',
);

# TEST
check_ita_tr(
    ['Castagneto'],
    "\N{HEBREW LETTER QOF}"
        . "\N{HEBREW POINT PATAH}"
        . "\N{HEBREW LETTER SAMEKH}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER TET}"
        . "\N{HEBREW POINT PATAH}"
        . "\N{HEBREW LETTER NUN}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER TET}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Castagneto',
);

# TEST
check_ita_tr(
    ['Vermiglio'],
    "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER MEM}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER LAMED}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Vermiglio',
);

# TEST
check_ita_tr(
    ['Guilmi'],
    "\N{HEBREW LETTER GIMEL}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER ALEF}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER LAMED}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER MEM}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW LETTER YOD}",
    'Guilmi',
);
