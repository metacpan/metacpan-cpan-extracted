#!/usr/bin/perl

use utf8;
use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Lingua::RO::Numbers',
    license           => 'artistic_2',
    dist_author       => q{Daniel "Trizen" Șuteu <trizenx@gmail.com>},
    dist_version_from => 'lib/Lingua/RO/Numbers.pm',
    dist_abstract     => 'Convert numeric values into their Romanian string equivalents and viceversa',
    release_status    => 'stable',

    configure_requires => {
                           'Module::Build' => 0,
                          },
    build_requires => {
                       'Test::More' => 0,
                      },

    extra_manify_args => { utf8 => 1 },

    meta_merge => {
                   resources => {
                                 repository => 'https://github.com/trizen/Lingua-RO-Numbers'
                                }
                  },
    requires => {
                 'perl'     => 5.006,
                 'utf8'     => 0,
                 'strict'   => 0,
                 'warnings' => 0,
                 'Encode'   => 0,
                },
    add_to_cleanup     => ['Lingua-RO-Numbers-*'],
    create_makefile_pl => 'traditional',
                                );

$builder->create_build_script();
