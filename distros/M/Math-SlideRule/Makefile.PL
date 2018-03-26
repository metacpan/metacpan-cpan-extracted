#!perl

use 5.010000;

use strict;
use warnings;
use ExtUtils::MakeMaker;

# perhaps stolen from mauke/Dir-Self
sub merge_key_into {
    my ( $href, $target, $source ) = @_;
    %{ $href->{$target} } = ( %{ $href->{$target} }, %{ delete $href->{$source} } );
}

my %params = (
    NAME          => 'Math::SlideRule',
    AUTHOR        => 'Jeremy Mates <jmates@cpan.org>',
    VERSION_FROM  => 'lib/Math/SlideRule.pm',
    ABSTRACT_FROM => 'lib/Math/SlideRule.pm',

    LICENSE          => 'bsd',

    MIN_PERL_VERSION => 5.10.0,

    CONFIGURE_REQUIRES => {
        'strict'              => 0,
        'ExtUtils::MakeMaker' => '6.48',
    },
    BUILD_REQUIRES => {},
    TEST_REQUIRES  => {
        'Test::Most'          => 0,
        'Pod::Coverage'       => 0.18,
        'Test::Pod::Coverage' => 1.08,
        'Test::Pod'           => 1.22,
        'lib'                 => 0,
    },
    # list everything due to certain linux vendors chopping up core
    # perl, or to otherwise detect and fail if being installed to a
    # broken perl install
    PREREQ_PM => { 'Moo' => 0, 'namespace::clean' => 0, 'Scalar::Util' => 0, },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            repository => {
                url  => 'git://github.com/thrig/Math-SlideRule.git',
                web  => 'https://github.com/thrig/Math-SlideRule',
                type => 'git',
            },
            bugtracker => { web => 'https://github.com/thrig/Math-SlideRule/issues' },
            homepage => 'https://github.com/thrig/Math-SlideRule',
            license  => ['https://opensource.org/licenses/BSD-3-Clause'],
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Math-SlideRule-*' },
);

(   my $mm_version = ExtUtils::MakeMaker->VERSION(
        $params{CONFIGURE_REQUIRES}{'ExtUtils::MakeMaker'}
    )
) =~ tr/_//d;

if ( $mm_version < 6.67_04 ) {
    # also stolen from mauke
    *ExtUtils::MM_Any::_add_requirements_to_meta_v1_4 =
      \&ExtUtils::MM_Any::_add_requirements_to_meta_v2;
}

if ( $mm_version < 6.63_03 ) {
    merge_key_into \%params, 'BUILD_REQUIRES', 'TEST_REQUIRES';
}

if ( $mm_version < 6.55_01 ) {
    merge_key_into \%params, 'CONFIGURE_REQUIRES', 'BUILD_REQUIRES';
}

if ( $mm_version < 6.51_03 ) {
    merge_key_into \%params, 'PREREQ_PM', 'CONFIGURE_REQUIRES';
}

WriteMakefile( ( MM->can('signature_target') ? ( SIGN => 1 ) : () ), %params );
