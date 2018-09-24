#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

# http://www.cpantesters.org/cpan/report/7c2a3994-bc30-11e8-83ca-8681f4fbe649
if ( $^O =~ m/haiku/i ) {
    print "Haiku OS does not support link() function\n";
    exit(0);
}

sub merge_key_into {
    my ( $href, $target, $source ) = @_;
    %{ $href->{$target} } = ( %{ $href->{$target} }, %{ delete $href->{$source} } );
}

my %params = (
    NAME         => 'File::AtomicWrite',
    ABSTRACT     => 'writes files atomically via rename()',
    AUTHOR       => 'Jeremy Mates <jmates@cpan.org>',
    VERSION_FROM => 'lib/File/AtomicWrite.pm',

    LICENSE  => 'bsd',
    PL_FILES => {},

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.48',
        'strict'              => 0,
    },
    BUILD_REQUIRES => {},
    TEST_REQUIRES  => {
        'Test::More' => 0,
        'lib'        => 0,
    },
    PREREQ_PM => {
        Carp           => 0,
        'Digest::SHA1' => 0,
        'File::Path'   => 0,
        'File::Spec'   => 0,
        'File::Temp'   => 0.18,
        'IO::Handle'   => 0,
    },

    META_MERGE => {
        'resources' => { repository => 'https://github.com/thrig/File-AtomicWrite', },
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
