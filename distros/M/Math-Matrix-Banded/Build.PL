use 5.014;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'Math::Matrix::Banded',
    license             => 'artistic_2',
    dist_author         => q{Lutz Gehlen <perl@lutzgehlen.de>},
    dist_version_from   => 'lib/Math/Matrix/Banded.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'perl'       => '5.14.0',
        'List::Util' => 0,
        'Moo'        => '2.002005',
        'Try::Tiny'  => 0,
    },
    add_to_cleanup     => [ 'Math-Matrix-Banded-*' ],
);

$builder->create_build_script();
