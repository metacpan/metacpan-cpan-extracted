require 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Linux::MCELog',
    VERSION_FROM      => 'lib/Linux/MCELog.pm',
    MIN_PERL_VERSION  => 5.008008,
    PREREQ_PM         => {
        'IO::Socket::UNIX' => '1.20',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/meow-watermelon/Linux-MCELog.git',
                web => 'https://github.com/meow-watermelon/Linux-MCELog',
            },
            bugtracker => {
                web => 'https://github.com/meow-watermelon/Linux-MCELog/issues',
            },
        },
    },
    ABSTRACT_FROM     => 'lib/Linux/MCELog.pm',
    AUTHOR            => 'Hui Li <herdingcat@yahoo.com>',
    LICENSE           => 'perl',
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Linux-MCELog*' },
);

