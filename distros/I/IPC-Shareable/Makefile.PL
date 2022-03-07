use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'IPC::Shareable',
    VERSION_FROM      => 'lib/IPC/Shareable.pm',
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/IPC/Shareable.pm',
       AUTHOR         => 'Steve Bertrand <steveb@cpan.org>') : ()),
    LIBS              => [],
    DEFINE            => '',
    INC               => '',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/ipc-shareable/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/ipc-shareable.git',
                web => 'https://github.com/stevieb9/ipc-shareable',
            },
        },
    },
    MIN_PERL_VERSION   => 5.010,
    LICENSE => 'perl_5',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.72,
    },
    BUILD_REQUIRES => {
        'IPC::Semaphore' => 0,
        'Mock::Sub'      => 0,
        'Test::More'       => 0,
        'Test::SharedFork' => 0.35,
    },
    PREREQ_PM    => {
        'JSON'          => 0,
        'Scalar::Util'  => 0,
        'Storable'      => 0.607,
        'String::CRC32' => 0,
    },
);
