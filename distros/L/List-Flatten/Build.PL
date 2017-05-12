use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'List::Flatten',
    license             => 'perl',
    dist_author         => 'Darko Obradovic <dobradovic@gmx.de>',
    dist_version_from   => 'lib/List/Flatten.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'List-Flatten-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
