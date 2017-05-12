use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'File::Edit::Portable',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/File/Edit/Portable.pm',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/file-edit-portable/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/file-edit-portable.git',
                web => 'https://github.com/stevieb9/file-edit-portable',
            },
        },
    },
    ABSTRACT_FROM    => 'lib/File/Edit/Portable.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
    },
    BUILD_REQUIRES => {
        'File::Tempdir' => 0,
        'Mock::Sub'  => '1.06',
    },
    PREREQ_PM => {
        'File::Find::Rule' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'File-Edit-Portable-*' },
);
