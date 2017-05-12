use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Lchown',
    dist_author => 'Nick Cleaton <nick@cleaton.net>',
    all_from    => 'lib/Lchown.pm',
    license     => 'perl',
    build_requires => {
        'ExtUtils::CBuilder' => 0,
        'Test::More'         => 0,
    },
    add_to_cleanup     => [ 'Lchown-*' ],
    create_makefile_pl => 'small',
);

$builder->create_build_script();
