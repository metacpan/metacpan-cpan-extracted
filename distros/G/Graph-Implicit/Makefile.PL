
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Graph-Implicit',
  NAME      => 'Graph::Implicit',
  AUTHOR    => 'Jesse\ Luehrs\ \<doy\ at\ tozt\ dot\ net\>',
  ABSTRACT  => 'graph\ algorithms\ for\ graphs\ that\ aren\\\'t\ necessarily\ fully\ specified',
  VERSION   => '0.03',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0',
    "Heap::Fibonacci::Fast" => '0',
    "Test::Deep" => '0',
    "List::MoreUtils" => '0',
  },
);
