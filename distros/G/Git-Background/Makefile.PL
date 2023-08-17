use 5.010;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    ABSTRACT           => 'use Git commands with Future',
    AUTHOR             => 'Sven Kirmess <sven.kirmess@kzone.ch>',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    DISTNAME         => 'Git-Background',
    LICENSE          => 'open_source',
    MIN_PERL_VERSION => '5.010',
    NAME             => 'Git::Background',
    PREREQ_PM        => {
        Carp               => 0,
        Future             => '0.49',
        'Path::Tiny'       => '0.125',
        'Proc::Background' => '1.30',
        'Scalar::Util'     => 0,
        parent             => 0,
        strict             => 0,
        warnings           => 0,
    },
    TEST_REQUIRES => {
        Cwd                     => 0,
        Encode                  => 0,
        Exporter                => 0,
        'File::Basename'        => 0,
        'File::Path'            => '2.07',
        'File::Spec'            => 0,
        'File::Spec::Functions' => 0,
        'Test::More'            => '0.88',
        lib                     => 0,
        overload                => 0,
    },
    VERSION => '0.008',
    test    => {
        TESTS => 't/*.t',
    },
);

my %FallbackPrereqs = (
    Carp                    => 0,
    Cwd                     => 0,
    Encode                  => 0,
    Exporter                => 0,
    'File::Basename'        => 0,
    'File::Path'            => '2.07',
    'File::Spec'            => 0,
    'File::Spec::Functions' => 0,
    Future                  => '0.49',
    'Path::Tiny'            => '0.125',
    'Proc::Background'      => '1.30',
    'Scalar::Util'          => 0,
    'Test::More'            => '0.88',
    lib                     => 0,
    overload                => 0,
    parent                  => 0,
    strict                  => 0,
    warnings                => 0,
);

if ( $ENV{AUTOMATED_TESTING} || $ENV{EXTENDED_TESTING} ) {
    $WriteMakefileArgs{test}{TESTS} .= ' xt/*.t';
    _add_extended_test_requirements();
}

if ( !eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

if ( !eval { ExtUtils::MakeMaker->VERSION(6.52) } ) {
    delete $WriteMakefileArgs{CONFIGURE_REQUIRES};
}

WriteMakefile(%WriteMakefileArgs);

sub test_requires {
    my ( $module, $version_or_range ) = @_;
    $WriteMakefileArgs{TEST_REQUIRES}{$module} = $FallbackPrereqs{$module} = $version_or_range;
    return;
}

sub _add_extended_test_requirements {
    test_requires( 'Test::MockModule', '0.14' );
    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
