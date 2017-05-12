#!perl -T

use 5.010;
use strict;
use warnings;

use Test::More tests => 15;
use Lingua::IT::Ita2heb;
use charnames ':full';

use lib './t/lib';
use CheckItaTrans qw(start_log check_ita_tr);

start_log(__FILE__);

check_ita_tr(
    'aba',
    "\N{HEBREW LETTER ALEF}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER BET}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'aba'
);

check_ita_tr(
    'abba',
    (
              "\N{HEBREW LETTER ALEF}"
            . "\N{HEBREW POINT PATAH}"
            . "\N{HEBREW LETTER BET}"
            . "\N{HEBREW POINT DAGESH OR MAPIQ}"
            . "\N{HEBREW POINT QAMATS}"
            . "\N{HEBREW LETTER HE}"
    ),
    'abba',
);

check_ita_tr(
    [ 'abba', disable_dagesh => 1 ],
    (
              "\N{HEBREW LETTER ALEF}"
            . "\N{HEBREW POINT PATAH}"
            . "\N{HEBREW LETTER BET}"
            . "\N{HEBREW POINT DAGESH OR MAPIQ}"
            . "\N{HEBREW POINT QAMATS}"
            . "\N{HEBREW LETTER HE}"
    ),
    'abba, disable dagesh'
);

check_ita_tr(
    'ama',
    "\N{HEBREW LETTER ALEF}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER MEM}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'ama',
);

check_ita_tr(
    'amma',
    "\N{HEBREW LETTER ALEF}"
        . "\N{HEBREW POINT PATAH}"
        . "\N{HEBREW LETTER MEM}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'amma',
);

check_ita_tr(
    [ 'amma', disable_dagesh => 1 ],
    "\N{HEBREW LETTER ALEF}"
        . "\N{HEBREW POINT PATAH}"
        . "\N{HEBREW LETTER MEM}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'amma, disable dagesh',
);

check_ita_tr(
    [ 'monte', disable_dagesh => 1 ],
    "\N{HEBREW LETTER MEM}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER NUN}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER TET}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER HE}",
    'amma, disable dagesh',
);

# Check that Dagesh is not added to Resh
check_ita_tr(
    'Serra',
    "\N{HEBREW LETTER SAMEKH}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'Serra',
);

check_ita_tr(
    'Cesena',
    "\N{HEBREW LETTER TSADI}"
        . "\N{HEBREW POINT SEGOL}"    # XXX Actually should be tsere
        . "\N{HEBREW PUNCTUATION GERESH}"
        . "\N{HEBREW LETTER ZAYIN}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER NUN}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER HE}",
    'Cesena'
);

check_ita_tr(
    'Quassolo',
    "\N{HEBREW LETTER QOF}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT PATAH}"
        . "\N{HEBREW LETTER SAMEKH}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER LAMED}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}",
    'Quassolo',
);

TODO: {
    #<<<
    local $TODO = 'handling qq is not yet implemented';
    #>>>

    check_ita_tr(
        'soqquadro',
        "\N{HEBREW LETTER SAMEKH}"
            . "\N{HEBREW LETTER VAV}"
            . "\N{HEBREW POINT HOLAM}"
            . "\N{HEBREW LETTER QOF}"
            . "\N{HEBREW POINT DAGESH OR MAPIQ}"
            . "\N{HEBREW POINT SHEVA}"
            . "\N{HEBREW LETTER VAV}"
            . "\N{HEBREW POINT PATAH}"
            . "\N{HEBREW LETTER DALET}"
            . "\N{HEBREW LETTER RESH}"
            . "\N{HEBREW LETTER VAV}"
            . "\N{HEBREW POINT HOLAM}",
        'soqquadro'
    );
}

check_ita_tr(
    'Filiorum',
    "\N{HEBREW LETTER PE}"
        . "\N{HEBREW POINT RAFE}"
        . "\N{HEBREW POINT HIRIQ}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER LAMED}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER YOD}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT HOLAM}"
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW LETTER VAV}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW LETTER FINAL MEM}",
    'Filiorum',
);

check_ita_tr(
    'San',
    "\N{HEBREW LETTER SAMEKH}"
        . "\N{HEBREW POINT QAMATS}"    # XXX Should be patah
        . "\N{HEBREW LETTER FINAL NUN}",
    'San',
);

check_ita_tr(
    'af',                              # not really a word
    "\N{HEBREW LETTER ALEF}"
        . "\N{HEBREW POINT QAMATS}"
        . "\N{HEBREW LETTER FINAL PE}",
    'Filiorum',
);

check_ita_tr(
    ['Brez'],
    "\N{HEBREW LETTER BET}"
        . "\N{HEBREW POINT DAGESH OR MAPIQ}"
        . "\N{HEBREW POINT SHEVA}"
        . "\N{HEBREW LETTER RESH}"
        . "\N{HEBREW POINT SEGOL}"
        . "\N{HEBREW LETTER FINAL TSADI}",
    'Brez',
);
