use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Debian::ModuleList',
    license             => 'perl',
    dist_author         => 'Ryan Niebur <ryanryan52@gmail.com>',
    dist_version_from   => 'lib/Debian/ModuleList.pm',
    build_requires => {
        'Test::More' => 0,
        'IO::All' => 0,
    },
    requires => {
        'IO::All' => 0,
    },
    add_to_cleanup      => [ 'Debian-ModuleList-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
