#!/usr/bin/perl

use utf8;
use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Math::BigNum',
    license           => 'artistic_2',
    dist_author       => q{Daniel Șuteu <trizenx@gmail.com>},
    dist_version_from => 'lib/Math/BigNum.pm',
    release_status    => 'stable',
    configure_requires => {
                           'Module::Build' => 0,
                          },
    build_requires => {
                       'Test::More' => 0,
                      },
    meta_merge => {
                   resources => {
                                 bugtracker => "https://github.com/trizen/Math-BigNum/issues",
                                 homepage   => "https://github.com/trizen/Math-BigNum",
                                 repository => "https://github.com/trizen/Math-BigNum",
                                },
                  },
    requires => {
                 'perl'                => '5.14.0',
                 'Carp'                => 0,
                 'POSIX'               => 0,
                 'Math::MPFR'          => 3.29,
                 'Math::GMPq'          => 0.41,
                 'Math::GMPz'          => 0.39,
                 'Class::Multimethods' => 0,
                },
    add_to_cleanup     => ['Math-BigNum-*'],
    create_makefile_pl => 'traditional',
                                );

$builder->create_build_script();
