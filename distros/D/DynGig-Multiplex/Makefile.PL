use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DynGig::Multiplex',
    AUTHOR              => 'Kan Liu <kan@cpan.org>',
    VERSION_FROM        => 'lib/DynGig/Multiplex.pm',
    ABSTRACT_FROM       => 'lib/DynGig/Multiplex.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
        'Errno' => 0,
        'Fcntl' => 0,
        'IO::Poll' => 0.07,
        'IPC::Open3' => 0,
        'POSIX' => 0,
        'Socket' => 0,
        'Time::HiRes' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DynGig-Multiplex-*' },
);
