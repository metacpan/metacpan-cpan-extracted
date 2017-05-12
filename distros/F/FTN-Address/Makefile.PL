use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'          => 'FTN::Address',
  'ABSTRACT'      => 'FTN Address processing',
  'AUTHOR'        => 'Robert James Clay <jame@rocasa.us>, Serguei Trouchelle <stro@railways.dp.ua>',
  'VERSION_FROM'  => 'lib/FTN/Address.pm',
  'LICENSE'       => 'perl',
  'PREREQ_PM' => {
      'Data::Define' => 1.02,
  },
);
