use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IMAP::Query',
    license             => 'artistic_2',
    dist_author         => q{Adam R. Schobelock <schobes@gmail.com>},
    dist_version_from   => 'lib/IMAP/Query.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Readonly' => 0,
        'List::MoreUtils' => 0,
    },
    add_to_cleanup     => [ 'IMAP-Query-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
