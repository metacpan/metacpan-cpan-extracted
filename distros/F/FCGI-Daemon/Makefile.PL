use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FCGI::Daemon',
    AUTHOR              => q{Dmitry Smirnov <onlyjob@cpan.org>},
    VERSION_FROM        => 'lib/FCGI/Daemon.pm',
    ABSTRACT_FROM       => 'lib/FCGI/Daemon.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'AGPLv3')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'BSD::Resource' => 0,
        'FCGI::ProcManager' => 0.28,
        'FCGI' => 0.82,
        'IO::Select' => 0,
        'Getopt::Std' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FCGI-Daemon-*' },
);
