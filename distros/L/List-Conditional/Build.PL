use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'List::Conditional',
    license             => 'perl',
    dist_author         => 'Darko Obradovic <dobradovic@gmx.de>',
    dist_version_from   => 'lib/List/Conditional.pm',
    build_requires => {
        'Test::More' => 0,
        'List::MoreUtils' => 0,
    },
    add_to_cleanup      => [ 'List-Conditional-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
