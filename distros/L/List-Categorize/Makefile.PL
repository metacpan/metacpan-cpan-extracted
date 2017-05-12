
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'List-Categorize',
  NAME      => 'List::Categorize',
  AUTHOR    => 'Bill\ Odom\ \<wnodom\@cpan\.org\>',
  ABSTRACT  => 'Categorize\ list\ items\ into\ a\ hash\ of\ named\ sublists\.',
  VERSION   => '0.03',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0',
    "Test::Deep" => '0',
    "Test::NoWarnings" => '0',
  },
);
