use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'          => 'FTN::Nodelist',
  'ABSTRACT'      => 'Process FTN Nodelist',
  'AUTHOR'        => 'Robert James Clay <jame@rocasa.us>, Serguei Trouchelle <stro@railways.dp.ua>',
  'VERSION_FROM'  => 'lib/FTN/Nodelist.pm',
  'LICENSE'       => 'perl',
  'PREREQ_PM' => {
      'FTN::Address' => 1.01,
  },
);
