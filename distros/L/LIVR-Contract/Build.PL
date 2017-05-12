use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'LIVR::Contract',
    license             => 'perl',
    dist_author         => q{Viktor Turskyi <koorchik@cpan.org>},
    dist_version_from   => 'lib/LIVR/Contract.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'                     => '5.010',
        'Validator::LIVR'          => '0.01',
        'Class::Method::Modifiers' => '2.04',
    },
    add_to_cleanup      => [ 'LIVR-Contract-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
