use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'M',
  AUTHOR => 'Matt S Trout (mst) <mst@shadowcat.co.uk>',
  VERSION_FROM => 'lib/M.pm',
  META_MERGE => {
    resources => {
      bugtracker => 'mailto:mst@shadowcat.co.uk',
    },
  },
);
