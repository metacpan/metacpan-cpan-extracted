use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'File::MimeInfo::Simple',
    AUTHOR           => 'David Moreno <damog@damog.net>',
    VERSION_FROM     => 'lib/File/MimeInfo/Simple.pm',
    ABSTRACT_FROM    => 'lib/File/MimeInfo/Simple.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.006',
    PREREQ_PM        => {
        'YAML::Syck' => 0,
        'Carp'       => 0,
        'Exporter'   => 0,
    },
    TEST_REQUIRES    => {
        'Test::More'  => 0,
        'File::Temp'  => 0,
        'File::Spec'  => 0,
    },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/damog/File-MimeInfo-Simple.git',
                web  => 'https://github.com/damog/File-MimeInfo-Simple',
            },
            bugtracker => {
                web => 'https://github.com/damog/File-MimeInfo-Simple/issues',
            },
        },
    },
);
