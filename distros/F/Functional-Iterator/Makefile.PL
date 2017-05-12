use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME                => 'Functional::Iterator',
  AUTHOR              => q{Belden Lyman <belden@cpan.org>},
  VERSION_FROM        => 'lib/Functional/Iterator.pm',
  ABSTRACT            => 'Generic iterator object for functional programming',
  LICENSE => 'perl',
  META_MERGE => {
    resources => {
      bugtracker => 'https://github.com/belden/perl-functional-iterator/issues',
    },
  },
  PL_FILES            => {},
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
