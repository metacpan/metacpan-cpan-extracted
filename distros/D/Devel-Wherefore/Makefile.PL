use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'Devel::Wherefore',
  VERSION_FROM => 'lib/Devel/Wherefore.pm',
  PREREQ_PM => {
    'Sub::Identify' => '0.14',
    'Package::Stash' => '0.37',
    'Data::Munge' => '0.097',
  },
);
