use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Image::Compare',
    AUTHOR           => q{Avi Finkel <avi@finkel.org>},
    VERSION_FROM     => 'lib/Image/Compare.pm',
    ABSTRACT_FROM    => 'lib/Image/Compare.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::CheckManifest' => 0,
        'Test::More'          => 0,
        'Test::Pod'           => 1.26,
        'Test::Pod::Coverage' => 1.08,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
        'Imager' => 0.54,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            license     => [ 'http://dev.perl.org/licenses/' ],
            bugtracker  => {
                web    => 'https://github.com/ivanych/Image-Compare/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/ivanych/Image-Compare.git',
                web  => 'https://github.com/ivanych/Image-Compare',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Image-Compare-*' },
);
