use 5.010_001;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name              => 'Loctools::Net',
    license                  => 'perl',
    dist_author              => 'Igor Afanasyev <igor.afanasyev@gmail.com>',
    dist_version_from        => 'lib/Loctools/Net.pm',
    release_status           => 'stable',
    configure_requires       => {
        'Module::Build'      => 0,
    },
    requires => {
        'perl'               => '5.10.0',
    },
    add_to_cleanup           => ['Loctools-Net-*', 'Makefile.PL', 'MYMETA.*', 'META.*', 'MANIFEST.bak', 'MANIFEST'],
    create_makefile_pl       => 'traditional',
);

$builder->create_build_script();
