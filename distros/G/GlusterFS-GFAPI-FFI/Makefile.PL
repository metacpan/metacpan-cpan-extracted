use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'GlusterFS::GFAPI::FFI',
    DISTNAME           => 'GlusterFS-GFAPI-FFI',
    AUTHOR             => 'Ji-Hyeon Gim <potatogim@gluesys.com>',
    VERSION_FROM       => 'lib/GlusterFS/GFAPI/FFI.pm',
    ABSTRACT_FROM      => 'lib/GlusterFS/GFAPI/FFI.pm',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'utf8'                   => 0,
        'strict'                 => 0,
        'warnings'               => 0,
        'overload'               => 0,
        'Fcntl'                  => 0,
        'POSIX'                  => 0,
        'Carp'                   => 0,
        'Try::Tiny'              => 0,
        'File::Spec'             => 0,
        'Scalar::Util::Numeric'  => 0,
        'List::MoreUtils'        => 0,
        'Moo'                    => 0,
        'Generator::Object'      => 0,
        'FFI::Platypus'          => 0,
        'FFI::Platypus::Declare' => 0,
        'FFI::Platypus::Buffer'  => 0,
        'FFI::Platypus::Memory'  => 0,
    },
    TEST_REQUIRES => {
        'utf8'         => 0,
        'locale'       => 0,
        'POSIX'        => 0,
        'Symbol'       => 0,
        'Data::Dumper' => 0,
        'Devel::Peek'  => 0,
        'IPC::Open3'   => 0,
        'IO::Select'   => 0,
        'List::Util'   => 0,
        'Scalar::Util' => 0,
        'Time::HiRes'  => 0,
        'Test::Deep'   => 0,
        'Test::More'   => 0,
        'Test::Most'   => 0,
        'Test::Class'  => 0,
    },
    PL_FILES => {},
    clean => {
        FILES => 'GlusterFS-GFAPI-FFI-*',
    },
    test => {
        TESTS => 't/*.t',
    },
    (
        eval { ExtUtils::MakeMaker->VERSION(6.46) }
            ? (
                META_MERGE => {
                    homepage => 'https://github.com/gluster/libgfapi-perl',
                    'meta-spec' => { version => 2 },
                    bugtracker => {
                        web => 'https://github.com/gluster/libgfapi-perl/issues',
                    },
                    resources   => {
                        type => 'git',
                        url  => 'https://github.com/gluster/libgfapi-perl.git',
                        web  => 'https://github.com/gluster/libgfapi-perl',
                    },
                    license => ['gpl_2', 'lgpl_3_0'],
                })
            : ()
    ),
);
