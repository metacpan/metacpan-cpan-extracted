use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'IPC::Open3::Utils',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/IPC/Open3/Utils.pm',
    ABSTRACT_FROM => 'lib/IPC/Open3/Utils.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,
        'IO::Select' => 0,
        'IPC::Open3' => 0,
        'IO::Handle' => 0,
    },
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean    => { FILES    => 'IPC-Open3-Utils-*' },
    META_ADD => {
        'meta-spec'    => { version => 2 },
        dynamic_config => 0,
        resources      => {
            repository => {
                url  => 'https://github.com/drmuey/p5-IPC-Open3-Utils.git',
                web  => 'https://github.com/drmuey/p5-IPC-Open3-Utils',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/drmuey/p5-IPC-Open3-Utils/issues',
            },
        },
    },
);
