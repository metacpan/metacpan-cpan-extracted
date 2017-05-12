use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Gtk2::Ex::MindMapView',
    license             => 'perl',
    dist_author         => 'James Muir <hemlock@vtlink.net>',
    dist_version_from   => 'lib/Gtk2/Ex/MindMapView.pm',
    requires => {
        'Test::More' => 0,
        'Graph'      => 0.67,
        'Gnome2::Canvas' => 1.002,
        'Glib'       => 1.105,
    },
    add_to_cleanup      => [ 'Gtk2-Ex-MindMapView-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
