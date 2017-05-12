use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Flexnet::lmutil',
    license             => 'perl',
    create_license	=> 1,
    dist_author         => q{Christopher Odenbach <odenbach@uni-paderborn.de>},
    dist_version_from   => 'lib/Flexnet/lmutil.pm',
    build_requires => {
        'Test::More' => 0,
    },
    configure_requires => {
        'Module::Build' => 0,
    },
    requires => {
        'perl' => 5.006,
        'File::Which' => 1.09,
    },
    add_to_cleanup      => [ 'Flexnet-lmutil-*' ],
    create_makefile_pl => 'traditional',
    create_readme => 1,
);

$builder->create_build_script();
