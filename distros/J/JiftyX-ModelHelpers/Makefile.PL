
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'JiftyX-ModelHelpers',
  NAME      => 'JiftyX::ModelHelpers',
  AUTHOR    => 'Kang\-min\ Liu\ \<gugod\@gugod\.org\>',
  ABSTRACT  => 'Make it simpler to fetch records in Jifty.',
  VERSION   => '0.23',
  test => { TESTS     => 't/*.t t/*/t/*.t' },
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'mit') : ()),
  PREREQ_PM    => {
    "Jifty" => '0.80408',
    "Exporter" => '5.62',
  },
);
