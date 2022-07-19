use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;

if (!$ENV{'ALLOW_NONLINUX'}) {
    die "OS not supported: $^O$/" if $^O ne 'linux';
}

WriteMakefile(
    NAME              => 'Linux::WireGuard',
    VERSION_FROM      => 'lib/Linux/WireGuard.pm', # finds $VERSION
    ABSTRACT_FROM  => 'lib/Linux/WireGuard.pm', # retrieve abstract from module
    AUTHOR         => [
        'Felipe Gasper (FELIPE)',
    ],

    LICENSE => "perl_5",

    INC => join(
        q< >,
        '-Wall',
        '-std=c99',
    ),

    OBJECT => join(
        q< >,
        '$(BASEEXT)$(OBJ_EXT)',
        'libwireguard.o',
    ),

    PMLIBDIRS => ['lib'],

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-Linux-WireGuard.git',
                web => 'https://github.com/FGasper/p5-Linux-WireGuard',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Linux-WireGuard/issues',
            },
        },
    },
);
