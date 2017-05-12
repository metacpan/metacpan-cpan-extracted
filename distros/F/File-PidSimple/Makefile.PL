BEGIN { require 5.006; };

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'File::PidSimple',
  AUTHOR        => 'Boris Zentner <bzm@2bz.de>',
  VERSION_FROM  => 'lib/File/PidSimple.pm',
  ABSTRACT_FROM => 'lib/File/PidSimple.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More'     => 0,
    'Carp'           => 0,
    'File::Basename' => 0,
    'File::Spec'     => 0,

    #        'version'    => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'File-PidSimple-*' },
);
