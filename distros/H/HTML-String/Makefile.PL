use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';


WriteMakefile(
  NAME => 'HTML::String',
  VERSION_FROM => 'lib/HTML/String.pm',
  PREREQ_PM => {
    'Safe::Isa' => 1,
    'Data::Munge' => '0.04',
    'B::Hooks::EndOfScope' => '0.11',
    'strictures' => 1,
    'UNIVERSAL::ref' => 0.14,
  }
);
