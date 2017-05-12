use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'List::Search',
    license           => 'perl',
    dist_author       => 'Edmund von der Burg <evdb@ecclestoad.co.uk>',
    dist_version_from => 'lib/List/Search.pm',

    requires => { 'Carp' => 0, },

    build_requires => {
        'Module::Build' => 0,
        'Data::Dumper'  => 0,
        'Test::More'    => 0,
    },

    create_makefile_pl => 'passthrough',
);

$builder->create_build_script();
