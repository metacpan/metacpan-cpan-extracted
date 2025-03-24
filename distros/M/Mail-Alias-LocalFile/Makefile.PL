use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mail::Alias::LocalFile',
    AUTHOR           => q{Russ Brewer (RBREW) <rbrew@cpan.org>},
    VERSION_FROM     => 'lib/Mail/Alias/LocalFile.pm',
    ABSTRACT_FROM    => 'lib/Mail/Alias/LocalFile.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.012',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'Test::Deep' => '0',
        'Test::Exception' => '0',
    },
    PREREQ_PM => {
        'Moo'                => '0',
        'namespace::autoclean' => '0',
        'Email::Valid'       => '0',
        'Scalar::Util'       => '0',
        'Data::Dumper::Concise' => '0',
        'Types::Standard'    => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mail-Alias-LocalFile-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/usna78/Mail-Alias-LocalFile.git',
                web  => 'https://github.com/usna78/Mail-Alias-LocalFile',
            },
            bugtracker => {
                web => 'https://github.com/usna78/Mail-Alias-LocalFile/issues',
            },
        },
    },
);
