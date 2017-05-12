use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'File::CountLines',
    dist_author        => 'Moritz Lenz',
    dist_abstract      => 'Efficiently count the number of line breaks in a file',
    dist_version_from  => 'lib/File/CountLines.pm',
    requires => {
        'Exporter'          => '5.57',
        'Carp'              => 0,
        'charnames'         => 1.01,
        'warnings'          => 0,
        'strict'            => 0,
    },
    recommends         => {},
    sign               => 0,
);
$build->create_build_script;

# vim: sw=4 ts=4 expandtab
