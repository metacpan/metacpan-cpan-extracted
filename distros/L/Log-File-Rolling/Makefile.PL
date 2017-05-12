use strict;

use ExtUtils::MakeMaker;

my %args = (
    NAME => 'Log::File::Rolling',
    VERSION_FROM => 'lib/Log/File/Rolling.pm',
    PREREQ_PM => {
      'Time::Piece' => 0,
    },
    AUTHOR => 'M. Jacob <jacob@j-e-b.net>', ## Forked from Log::Dispatch::File::Rolling 1.09
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
      resources => {
        repository => 'git://github.com/hoytech/Log-File-Rolling.git',
        bugtracker => 'https://github.com/hoytech/Log-File-Rolling/issues',
      },
    },
);

WriteMakefile(%args)
