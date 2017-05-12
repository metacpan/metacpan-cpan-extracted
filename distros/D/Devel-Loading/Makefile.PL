
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Devel-Loading',
  NAME      => 'Devel::Loading',
  AUTHOR    => 'Shawn\ M\ Moore\ \<sartak\@bestpractical\.com\>',
  ABSTRACT  => 'Run code before each module is loaded',
  VERSION   => '0.01',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {

  },
);
