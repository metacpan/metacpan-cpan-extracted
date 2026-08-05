use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'LightTCP::Server',
    AUTHOR            => 'Hans Harder E<lt>hans[at]atbas.orgE<gt>',
    VERSION_FROM      => 'lib/LightTCP/Server.pm',
    ABSTRACT_FROM     => 'lib/LightTCP/Server.pm',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.010',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'IO::Socket::INET' => 0,
        'IPC::Open3'       => 0,
        'File::Temp'       => 0,
        # threads is recommended but not mandatory
        'threads'          => 0,
        'threads::shared'  => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://codeberg.org/HansH111/LightTCP-Server.pm.git',
                web  => 'https://codeberg.org/HansH111/LightTCP-Server.pm',
            },
            bugtracker => {
                web => 'https://codeberg.org/HansH111/LightTCP-Server.pm/issues',
            },
        },
        provides => {
            'LightTCP::Server' => {
                file    => 'lib/LightTCP/Server.pm',
                version => '2.05',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'LightTCP-Server-*' },
    test  => { TESTS => 't/*.t' },
);
