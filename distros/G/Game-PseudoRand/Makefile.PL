use 5.10.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

sub merge_key_into {
    my ( $href, $target, $source ) = @_;
    %{ $href->{$target} } = ( %{ $href->{$target} }, %{ delete $href->{$source} } );
}

my %params = (
    NAME         => 'Game::PseudoRand',
    ABSTRACT     => 'pseudo random distribution functions',
    AUTHOR       => 'Jeremy Mates <jmates@cpan.org>',
    VERSION_FROM => 'lib/Game/PseudoRand.pm',

    MIN_PERL_VERSION => '5.10.0',

    LICENSE  => 'bsd',
    PL_FILES => {},

    CONFIGURE_REQUIRES => {
        'strict'              => 0,
        'ExtUtils::MakeMaker' => '6.48',
    },
    BUILD_REQUIRES => {},
    TEST_REQUIRES  => {
        'Test::More' => '0.88',    # done_testing
        'Test::Most' => 0,
        'lib'        => 0,
    },
    PREREQ_PM => {
        'Carp'   => 0,
        'strict' => 0,
    },

    META_MERGE =>
      { resources => { repository => 'https://github.com/thrig/Game-PseudoRand' } },
);

(   my $mm_version = ExtUtils::MakeMaker->VERSION(
        $params{CONFIGURE_REQUIRES}{'ExtUtils::MakeMaker'}
    )
) =~ tr/_//d;

if ( $mm_version < 6.67_04 ) {
    # Why? For the glory of the Butlarian Jihad, of course!
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
