use 5.006;

use strict;
use warnings;
use ExtUtils::MakeMaker;

# TODO no idea if pread/pwrite available, maybe if someone has the time
# and can provide patches... TODO there's also a dist check module, but
# alas I am off the Internet so cannot lookup the exact name nor use it
if ( $^O =~ m/MSWin32/ ) {
    print "Sorry, no automated install is available on Windows.\n";
    exit(0);
}

# I think you know where this was stolen from by now
sub merge_key_into {
    my ( $href, $target, $source ) = @_;
    %{ $href->{$target} } = ( %{ $href->{$target} }, %{ delete $href->{$source} } );
}

my %params = (
    NAME         => 'File::ReplaceBytes',
    ABSTRACT     => 'read or replace arbitrary data in files',
    AUTHOR       => 'Jeremy Mates <jmates@cpan.org>',
    VERSION_FROM => 'lib/File/ReplaceBytes.pm',

    LICENSE  => 'artistic_2',
    PL_FILES => {},

    CONFIGURE_REQUIRES => {
        'strict'              => 0,
        'ExtUtils::MakeMaker' => '6.48',
    },
    BUILD_REQUIRES => {},
    TEST_REQUIRES  => {
        'lib'        => 0,
        'Test::Most' => 0,
    },
    PREREQ_PM => { 'strict' => 0, },

    META_MERGE => {
        'meta-spec'         => { version => 2 },
        'homepageresources' => {
            repository => {
                url  => 'git://github.com/thrig/File-ReplaceBytes.git',
                web  => 'https://github.com/thrig/File-ReplaceBytes',
                type => 'git',
            },
        },
    },
);

(   my $mm_version = ExtUtils::MakeMaker->VERSION(
        $params{CONFIGURE_REQUIRES}{'ExtUtils::MakeMaker'}
    )
) =~ tr/_//d;

if ( $mm_version < 6.67_04 ) {
    # Why? For the glory of APUE!
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
