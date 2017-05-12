#!perl -T

use 5.010;
use strict;
use warnings;

use Test::More tests => 17;
use Lingua::IT::Ita2heb;
use charnames ':full';

use lib './t/lib';
use CheckItaTrans qw(start_log check_ita_tr);

start_log(__FILE__);

# TEST
check_ita_tr(
    ['eco'],
    "\N{HEBREW LETTER ALEF}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER QOF}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'eco',
);

# TEST
check_ita_tr(
    ['ecco'],
    "\N{HEBREW LETTER ALEF}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER QOF}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'ecco',
);

# TEST
check_ita_tr(
    ['capo'],
    "\N{HEBREW LETTER QOF}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER PE}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'capo',
);

# TEST
check_ita_tr(
    ['cibo'],
    "\N{HEBREW LETTER TSADI}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER BET}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'cibo',
);

# TEST
check_ita_tr(
    [ 'cibo', ascii_geresh => 1 ],
    "\N{HEBREW LETTER TSADI}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{APOSTROPHE}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER BET}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'cibo, ascii geresh',
);

# TEST
check_ita_tr(
    ['ciabatta'],
    "\N{HEBREW LETTER TSADI}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER BET}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT PATAH}"
        . "\N{HEBREW LETTER TET}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'ciabatta',
);

# TEST
check_ita_tr(
    ['cieco'],
    "\N{HEBREW LETTER TSADI}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER QOF}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'cieco',
);

# TEST
check_ita_tr(
    'cio' . "\N{LATIN SMALL LETTER E WITH GRAVE}",
    "\N{HEBREW LETTER TSADI}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER ALEF}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER HE}",
    q(cioe')
);

# TEST
check_ita_tr(
    'ciuco',
    "\N{HEBREW LETTER TSADI}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"    # shuruk
        . "\N{HEBREW LETTER QOF}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'ciuco',
);

# TEST
check_ita_tr(
    ['Cicciano'],
    "\N{HEBREW LETTER TSADI}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER TSADI}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER NUN}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Cicciano',
);

# TEST
check_ita_tr(
    ['Rocchetta'],
    "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER QOF}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER TET}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'Rocchetta',
);

# TEST
check_ita_tr(
    ['Acqua'],
    "\N{HEBREW LETTER ALEF}"
        . "\N{HEBREW POINT PATAH}"
        . "\N{HEBREW LETTER QOF}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'Acqua',
);

# TEST
check_ita_tr(
    [ 'Acqua', disable_dagesh => 1 ],
    "\N{HEBREW LETTER ALEF}"
        . "\N{HEBREW POINT PATAH}"
        . "\N{HEBREW LETTER QOF}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'Acqua, disable_dagesh',
);

# TEST
check_ita_tr(
    ['Brescia'],
    "\N{HEBREW LETTER BET}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER SHIN}"
        . "\N{HEBREW POINT SHIN DOT}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'Brescia',
);

# TEST
check_ita_tr(
    ['Volsci'],
    "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER LAMED}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER SHIN}"
        . "\N{HEBREW POINT SHIN DOT}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW LETTER YOD}",
    'Volsci'
);

# TEST
check_ita_tr(
    ['Scerni'],
    "\N{HEBREW LETTER SHIN}"
        . "\N{HEBREW POINT SHIN DOT}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER NUN}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW LETTER YOD}",
    'Scerni',
);

# TEST
check_ita_tr(
    ['Cimolais'],
    "\N{HEBREW LETTER TSADI}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER MEM}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER LAMED}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER ALEF}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER SAMEKH}",
    'Cimolais',
);
