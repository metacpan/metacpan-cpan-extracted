#!/usr/bin/perl

use utf8;
use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    dist_name         => 'Linux-DesktopFiles',
    license           => 'perl',
    dist_author       => q{Daniel "Trizen" Șuteu <trizenx@gmail.com>},
    dist_version_from => 'lib/Linux/DesktopFiles.pm',
    dist_abstract     => 'Get and parse the Linux desktop files.',
    release_status    => 'stable',

    configure_requires => {
                           'Module::Build' => 0,
                          },
    meta_merge => {
                   resources => {
                                 bugtracker => "https://github.com/trizen/Linux-DesktopFiles/issues",
                                 homepage   => "https://github.com/trizen/Linux-DesktopFiles",
                                 repository => "https://github.com/trizen/Linux-DesktopFiles",
                                },
                  },

    requires => {
                 'perl'      => 5.014,
                 'GDBM_File' => 0,
                },

    add_to_cleanup     => ['Linux-DesktopFiles-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
