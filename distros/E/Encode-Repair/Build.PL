use strict;
use warnings;
use Module::Build;
require 5.008001;

my $build = Module::Build->new(
    create_readme      => 0,
    create_makefile_pl => 'traditional',
    license            => 'artistic_2',
    module_name        => 'Encode::Repair',
    dist_author        => 'Moritz Lenz',
    dist_abstract      => undef,
    dist_version_from  => 'lib/Encode/Repair.pm',
    requires => {
        'perl'               => '5.008001',
        'Test::More'         => 0,
        'Algorithm::Loops'   => 0,
        'Encode'             => 0,
        'strict'             => 0,
        'warnings'           => 0,
        'charnames'          => 0,
        'Exporter'           => 0,
    },
    recommends         => {},
    sign               => 0,
);
$build->create_build_script;

# vim: sw=4 ts=4 expandtab
