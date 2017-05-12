use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Inline::Module::LeanDist',
    VERSION_FROM => 'lib/Inline/Module/LeanDist.pm',
    PREREQ_PM => {
      'File::Path' => 0,
      'File::Find' => 0,
      'File::Copy' => 0,
      'Inline' => 0,
      'Inline::C' => 0,
    },
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
        resources => {
            repository => 'git://github.com/hoytech/Inline-Module-LeanDist.git',
            bugtracker => 'https://github.com/hoytech/Inline-Module-LeanDist/issues',
        },
    },
);

WriteMakefile(%args);
