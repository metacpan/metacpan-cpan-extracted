use 5.006;
use strict;
use warnings;
use Module::Build;
my $builder = Module::Build->new(
    module_name        => 'LPDS',
    license            => 'perl',
    dist_author        => q{"Xi Yang" <"yangx@im.ac.cn">},
    dist_version_from  => 'lib/LPDS.pm',
    configure_requires => { 'Module::Build' => 0.38 },
    build_requires     => { 'Test::More' => 0, },
    requires           => {
        'perl'           => '5.10.0',
        'Moose'          => 0,
        'YAML'           => 0,
        'Gtk2'           => 0,
        'File::ShareDir' => 0,
        'Goo::Canvas'    => 0
    },
    add_to_cleanup     => ['LPDS-*'],
    create_makefile_pl => 'traditional',
    share_dir          => 'data'
);
$builder->create_build_script();
