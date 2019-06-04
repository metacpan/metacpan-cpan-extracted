#!perl

use 5.24.0;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install qw(install_share);

install_share 'levels';

sub merge_key_into {
    my ( $href, $target, $source ) = @_;
    %{ $href->{$target} } = ( %{ $href->{$target} }, %{ delete $href->{$source} } );
}

my %params = (
    NAME          => 'Game::PlatformsOfPeril',
    AUTHOR        => 'Jeremy Mates <jmates@cpan.org>',
    VERSION_FROM  => 'lib/Game/PlatformsOfPeril.pm',
    ABSTRACT_FROM => 'lib/Game/PlatformsOfPeril.pm',

    EXE_FILES => [qw(pperil)],

    MIN_PERL_VERSION => '5.24.0',

    LICENSE  => 'bsd',
    PL_FILES => {},

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => '6.48',
        'File::ShareDir::Install' => 0,
        'strict'                  => 0,
    },
    BUILD_REQUIRES => {},
    TEST_REQUIRES  => {
        'Test::More' => 0,
        'lib'        => 0,
    },
    PREREQ_PM => {
        'File::ShareDir'      => 0,
        'File::Spec'          => 0,
        'List::PriorityQueue' => 0,
        'List::Util'          => 0,
        'List::UtilsBy'       => 0.06,
        'Scalar::Util'        => 0,
        'Term::ReadKey'       => 0,
        'Time::HiRes'         => 0,
        'POSIX'               => 0,
        'strict'              => 0,
    },

    META_MERGE => {
        'resources' =>
          { repository => 'https://github.com/thrig/Game-PlatformsOfPeril', },
    },
);

(   my $mm_version = ExtUtils::MakeMaker->VERSION(
        $params{CONFIGURE_REQUIRES}{'ExtUtils::MakeMaker'}
    )
) =~ tr/_//d;

if ( $mm_version < 6.67_04 ) {
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

package MY;
use File::ShareDir::Install qw(postamble);
