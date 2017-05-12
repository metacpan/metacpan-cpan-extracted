# $Id: Makefile.PL 7 2009-09-16 15:41:34Z stro $

use strict;
use warnings;
use 5.008;

use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'          => 'Lingua::Cyrillic::Translit::ICAO',
  'ABSTRACT'      => "Cyrillic characters transliteration into ICAO Doc 9303",
  'AUTHOR'        => 'Serguei Trouchelle <stro@railways.dp.ua>',
  'VERSION_FROM'  => 'ICAO.pm',
  'LICENSE'       => 'perl',
  'PREREQ_PM' => {
    'Encode' => 0,
  },

);
