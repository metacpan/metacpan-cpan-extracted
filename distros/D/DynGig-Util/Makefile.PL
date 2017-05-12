use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DynGig::Util',
    AUTHOR              => 'Kan Liu <kan@cpan.org>',
    VERSION_FROM        => 'lib/DynGig/Util.pm',
    ABSTRACT_FROM       => 'lib/DynGig/Util.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp' => 0,
        'Cwd' => 0,
        'DateTime' => 0,
        'DBI' => 0,
        'DynGig::Range::Time' => 0,
        'Errno' => 0,
        'Fcntl' => 0,
        'File::Copy' => 0,
        'File::Spec' => 0,
        'File::Temp' => 0,
        'IO::Select' => 0,
        'POSIX' => 0,
        'Socket' => 0,
        'Thread::Queue' => 2.12,
        'threads' => 1.86,
        'Thread::Semaphore' => 2.12,
        'Time::HiRes' => 0,
        'YAML::XS' => 0.38,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DynGig-Util-*' },
);
