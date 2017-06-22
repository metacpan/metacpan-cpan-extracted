use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use 5.010;

(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'Method::Signatures::PP',
  VERSION_FROM => 'lib/Method/Signatures/PP.pm',
  PREREQ_PM => { PPR => 0 },
);
