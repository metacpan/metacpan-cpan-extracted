use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'          => 'Lingua::UK::Jcuken',
  'ABSTRACT'      => "Convert between QWERTY/JCUKEN",
  'AUTHOR'        => 'Serguei Trouchelle <stro@railways.dp.ua>',
  'VERSION_FROM'  => 'Jcuken.pm',
  'LICENSE'       => 'perl',
  'PREREQ_PM' => {
    'Encode' => 0,
  },
);
