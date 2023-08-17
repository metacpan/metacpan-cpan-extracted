require 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile (
  NAME         => 'File-Tools',
  VERSION_FROM => 'lib/File/Tools.pm',
  AUTHOR       => 'Gabor Szabo',
  PREREQ_PM    => {
     'File::Basename'            => '0',
     'File::Copy'                => '0',
     'Cwd'                       => '0',
     'POSIX'                     => '0',
     'File::Find'                => '0',
     'File::Path'                => '0',
     'File::Temp'                => '0',
  },
  BUILD_REQUIRES => {
                     'Test::More'    => '0.80',
                     'Test::NoWarnings' => 0,
                     'File::Temp'    => 0,
  },
  LICENSE => 'perl',
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
          type => 'git',
          url  => 'https://github.com/szabgab/File-Tools.git',
          web  => 'https://github.com/szabgab/File-Tools',
      },
      bugtracker => {
          web => 'https://github.com/szabgab/File-Tools/issues'
      },
    }
  },
);
