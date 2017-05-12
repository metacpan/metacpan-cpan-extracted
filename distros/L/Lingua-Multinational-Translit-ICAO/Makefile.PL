use strict;
use warnings;
use 5.008;

# $Id: Makefile.PL 6 2009-09-16 15:37:46Z stro $ 

use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'          => 'Lingua::Multinational::Translit::ICAO',
  'ABSTRACT'      => "Multinational characters transliteration into ICAO Doc 9303",
  'AUTHOR'        => 'Serguei Trouchelle <stro@railways.dp.ua>',
  'VERSION_FROM'  => 'ICAO.pm',
  'LICENSE'       => 'perl',
  'PREREQ_PM' => {
    'Encode' => 0,
  },
);
