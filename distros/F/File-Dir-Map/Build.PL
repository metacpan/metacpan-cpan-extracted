use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'File::Dir::Map',
    license           => 'perl',
    dist_author       => q{Eugene Grigoriev <perl@sizur.com>},
    dist_version_from => 'lib/File/Dir/Map.pm',
    build_requires    => {
        'Test::More'    => 0,
        'common::sense' => 3.1,
        'File::Path'    => 2.08,
    },
    add_to_cleanup     => ['File-Dir-Map-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
