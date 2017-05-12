use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME                => 'Hash::MostUtils',
  AUTHOR              => q{Belden Lyman <belden@cpan.org>},
  VERSION_FROM        => 'lib/Hash/MostUtils.pm',
  ABSTRACT            => 'Pairwise list manipulators',
  LICENSE => 'perl',
  PL_FILES            => {},
  PREREQ_PM => {
    # I wrote provide.pm in the context of solving the leach() problem
    # that this module has to deal with; it would be the height of
    # jerkiness *towards myself* to not use provide.pm.
    provide => '0.02',
  },
  META_MERGE => {
    resources => {
      bugtracker => 'https://github.com/belden/perl-hash-mostutils/issues',
      repository => 'git://github.com/belden/perl-hash-mostutils.git',
      homepage => 'https://github.com/belden/perl-hash-mostutils',
    },
  },
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
