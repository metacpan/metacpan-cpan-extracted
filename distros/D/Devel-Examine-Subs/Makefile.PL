use 5.008;
use warnings;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile
(
  PL_FILES => {},
  EXE_FILES => [],
  NAME => 'Devel::Examine::Subs',
  MIN_PERL_VERSION => '5.008',
  LICENSE => 'perl',
  INSTALLDIRS => 'site',
  VERSION_FROM => 'lib/Devel/Examine/Subs.pm',
  META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
             bugtracker => {
                web => 'https://github.com/stevieb9/devel-examine-subs/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/devel-examine-subs.git',
                web => 'https://github.com/stevieb9/devel-examine-subs',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'Cwd' => 0,
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Mock::Sub' => '1.06',
        'Test::More' => 0,
        'Test::Trap' => 0,
    },
    PREREQ_PM => {
       'Carp' => 0,
       'Data::Compare' => 0,
       'Data::Dumper' => 0,
       'File::Basename' => 0,
       'File::Edit::Portable' => '1.24',
       'PPI' => 0,
       'Symbol' => 0,
    },
);
