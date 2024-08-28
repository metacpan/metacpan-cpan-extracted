#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS  = 1;

install_share dist => "share";

WriteMakefile(
    NAME               => 'Map::Tube::Rome',
    VERSION_FROM       => 'lib/Map/Tube/Rome.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/Rome.pm',
    LICENSE            => 'artistic_2',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    MIN_PERL_VERSION   => 5.010,
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 0, 'File::ShareDir::Install' => '0.13'},
    BUILD_REQUIRES     => {'Test::More'          => 0},
    PREREQ_PM          =>
        {'Moo' => '2.000000', 'namespace::autoclean' => '0.28', 'File::ShareDir' => '1.114', 'Map::Tube' => '3.72'},
    META_MERGE => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-Map-Tube-Rome/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Map-Tube-Rome',
                web  => 'https://github.com/giterlizzi/perl-Map-Tube-Rome'
            },
        },
        x_purl => 'pkg:cpan/GDT/Map-Tube-Rome'
    },
    test  => {TESTS    => 't/*.t'},
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'Map-Tube-Rome-*'},
);

package MY;
use File::ShareDir::Install 'postamble';
