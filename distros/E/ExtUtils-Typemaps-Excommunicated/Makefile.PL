use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME' => 'ExtUtils::Typemaps::Excommunicated',
  'VERSION_FROM' => 'lib/ExtUtils/Typemaps/Excommunicated.pm',
  'PREREQ_PM' => {
    'Carp' => 0,
    'ExtUtils::Typemaps' => '3.14',
  },
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/ExtUtils/Typemaps/Excommunicated.pm',
     AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
