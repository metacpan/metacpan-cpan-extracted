require 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile (
  NAME         => 'File-Open-OOP',
  VERSION_FROM => 'lib/File/Open/OOP.pm',
  AUTHOR       => 'Gabor Szabo',
  PREREQ_PM    => { 
                     'File::Open' => '0.031',
  },
  BUILD_REQUIRES => {
                     'Test::More'    => '0.80',
                     'Test::Exception' => '0.31',
                     'File::Temp'    => 0,
  },
);
