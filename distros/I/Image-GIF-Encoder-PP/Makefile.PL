use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Image::GIF::Encoder::PP',
    AUTHOR           => "Gavin Hayes <gahayes\@cpan.org>",
    VERSION_FROM     => 'lib/Image/GIF/Encoder/PP.pm',
    ABSTRACT_FROM    => 'lib/Image/GIF/Encoder/PP.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    PREREQ_PM => {
        'version'    => '0.77',
    },
    TEST_REQUIRES => {
        'MIME::Base64' => '0'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => ['Image-GIF-Encoder-PP-*', 't/*.gif']},
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/G4Vi/gifenc-pl.git',
                web  => 'https://github.com/G4Vi/gifenc-pl',
            },
            bugtracker => {
                web => 'https://github.com/G4Vi/gifenc-pl/issues'
            },
            homepage   => 'https://github.com/G4Vi/gifenc-pl',
        },
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

my %min_eumm_version = (
    CONFIGURE_REQUIRES => '6.52',
    MIN_PERL_VERSION   => '6.48',
    LICENSE            => '6.31',
    META_MERGE         => '6.46',
);
for my $parameter ( keys %min_eumm_version ) {
    delete $WriteMakefileArgs{$parameter}
      unless eval {
          ExtUtils::MakeMaker->VERSION( $min_eumm_version{$parameter} );
          1;
      };
}

WriteMakefile(%WriteMakefileArgs);
