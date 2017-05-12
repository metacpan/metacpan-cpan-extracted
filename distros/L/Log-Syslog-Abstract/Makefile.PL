use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Log::Syslog::Abstract',
    AUTHOR              => q{Dave O'Neill <dmo@roaringpenguin.com>},
    VERSION_FROM        => 'lib/Log/Syslog/Abstract.pm',
    ABSTRACT_FROM       => 'lib/Log/Syslog/Abstract.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'Devel::Hide' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Log-Syslog-Abstract-*' },
);
