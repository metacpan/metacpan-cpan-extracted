use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib 'lib';
eval { require ExtUtils::MakeMaker::JSONMETA; };

WriteMakefile(
  NAME                => 'JSON-CPAN-Meta',
  AUTHOR              => 'Ricardo Signes <rjbs@cpan.org>',
  VERSION_FROM        => 'lib/JSON/CPAN/Meta.pm',
  ABSTRACT_FROM       => 'lib/JSON/CPAN/Meta.pm',
  PREREQ_PM => {
    'ExtUtils::MakeMaker' => 6, # actual minimum unknown
    'JSON'                => 2,
  },
);
