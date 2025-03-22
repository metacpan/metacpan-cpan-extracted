use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'EBook::Gutenberg',
    AUTHOR           => q{Samuel Young <samyoung12788@gmail.com>},
    VERSION_FROM     => 'lib/EBook/Gutenberg.pm',
    ABSTRACT_FROM    => 'lib/EBook/Gutenberg.pm',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'File::Copy' => '0',
        'File::Path' => '0',
        'File::Spec' => '0',
        'File::Temp' => '0.10',
    },
    PREREQ_PM => {
	    'Getopt::Long' => '0',
        'File::Copy' => '0',
        'File::Fetch' => '0',
        'File::Path' => '0',
        'File::Spec' => '0',
        'File::Temp' => '0.10',
        'JSON::PP' => '0',
        'List::Util' => '1.33',
        'Text::CSV_XS' => '0',
    },
    EXE_FILES => [
        'bin/gutenberg',
    ],
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                url => 'https://codeberg.org/1-1sam/gutenberg.git',
                web => 'https://codeberg.org/1-1sam/gutenberg',
                type => 'git',
            },
            bugtracker => {
                web => 'https://codeberg.org/1-1sam/gutenberg/issues',
            },
        },
	},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'EBook-Gutenberg-*' },
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

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };
delete $WriteMakefileArgs{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 };

WriteMakefile(%WriteMakefileArgs);
