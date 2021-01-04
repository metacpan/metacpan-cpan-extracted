use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use version;

WriteMakefile(
    NAME             => 'Dist::Mgr',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Dist/Mgr.pm',
    ABSTRACT_FROM    => 'lib/Dist/Mgr.pod',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/dist-mgr/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/dist-mgr.git',
                web => 'https://github.com/stevieb9/dist-mgr',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Capture::Tiny'      => 0,
        'File::Touch'        => 0,
        'Hook::Output::Tiny' => 0,
        'Mock::Sub'          => 0,
        'Test::More'         => 0,
    },
    PREREQ_PM => {
        'CPAN::Uploader'        => 0,
        'File::Find::Rule'      => 0,
        'File::Copy::Recursive' => 0,
        'File::Path'            => 0,
        'Module::Starter'       => '1.77',
        'PPI'                   => 0,
        'Term::ReadKey'         => 0,
        'Tie::File'             => 0,
        'version'               => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dist-Mgr-*' },
);
