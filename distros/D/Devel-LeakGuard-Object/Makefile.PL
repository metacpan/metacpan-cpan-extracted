use strict;
use warnings;

use ExtUtils::MakeMaker '6.64';

WriteMakefile(
    NAME            => 'Devel::LeakGuard::Object',
    ABSTRACT        => 'Scoped checks for object leaks',
    VERSION_FROM    => 'lib/Devel/LeakGuard/Object.pm',
    AUTHOR          => 'Andy Armstrong <andy@hexten.net>',
    LICENSE         => 'perl',
    MIN_PERL_VERSION => 5.008,
    PREREQ_PM => {
            'Carp'         => 0,
            'Data::Dumper' => 0,
            'Devel::Peek'  => 0,
            'List::Util'   => '1.19',
            'Scalar::Util' => '1.19',
        },
    BUILD_REQUIRES  => {
            'Test::More'        => '0.42',
            'Test::Differences' => 0,
        },
    TEST_REQUIRES   => {
            'latest'            => 0,
            'Capture::Tiny'     => 0,
            'Class::Load'       => 0,
            'File::Find'        => 0,
            'Test::Kwalitee'    => 0,
        },
    META_MERGE      => {
        resources => {
            repository  => 'https://github.com/AndyA/Devel--LeakGuard--Object.git',
            bugtracker  => 'https://github.com/AndyA/Devel--LeakGuard--Object/issues',
        },
    },
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean           => { FILES => 'Devel-LeakGuard-Object-*' },
    test            => { TESTS => join( ' ', (glob( 't/*.t'), glob('xt/author/*.t'))) },
);

sub MY::postamble {
    return <<'MAKE_FRAG';
critic:
	perlcritic -1 -q lib/ t/*.t xt/author/*.t

MAKE_FRAG
}

# vim: expandtab shiftwidth=4
