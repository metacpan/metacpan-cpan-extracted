use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'          => 'FindBin::Real',
  'ABSTRACT'      => 'Locate directory of original perl script',
  'AUTHOR'        => 'Serguei Trouchelle <stro@railways.dp.ua>',
  'VERSION_FROM'  => 'Real.pm',
  'LICENSE'       => 'perl',
);
