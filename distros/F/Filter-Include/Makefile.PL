# require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Filter::Include',
  VERSION_FROM => 'lib/Filter/Include.pm',
  AUTHOR       => 'Dan Brook',

  PREREQ_PM    => {
    'Filter::Simple' => '0.70',
    'Module::Locate' => '1.7',
    'Scalar::Util'   => '1.01',
  },
);
