use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'FTN::Message::serialno',
    license             => 'Artistic_2_0',
    dist_author         => q{Valery Kalesnik <valkoles@gmail.com>},
    dist_version_from   => 'lib/FTN/Message/serialno.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'File::Spec' => 0,
    },
    add_to_cleanup     => [ 'FTN-Message-serialno-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
