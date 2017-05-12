use strict;
use Glib qw/TRUE FALSE/;
use Geo::Raster;
use Gtk2::Ex::Geo;
use Gtk2::TestHelper tests => 15;
eval {
    require IPC::Gnuplot;
};
my $have_gnuplot = !$@;

my($window, $gis) = setup(classes => [qw/Gtk2::Ex::Geo::Layer Geo::Raster::Layer/]);
ok(1);

if ($have_gnuplot) {
    my $gnuplot = IPC::Gnuplot->new();
    $gis->register_function( name => 'plot', object => $gnuplot );
    $gis->register_function( name => 'p', object => $gnuplot );
}

my $layer = Geo::Raster->new(100, 100);
$gis->add_layer($layer);

$window->show;
ok(1);

$layer->open_symbols_dialog($gis)->destroy;
ok(1);
$layer->open_colors_dialog($gis)->destroy;
ok(1);
$layer->open_labeling_dialog($gis)->destroy;
ok(1);
$layer->open_properties_dialog($gis)->destroy;
ok(1);
$layer->open_copy_dialog($gis)->destroy;
ok(1);
$layer->open_polygonize_dialog($gis)->destroy;
ok(1);

eval {
    $layer->open_features_dialog($gis)->destroy;
};
#ok($@ =~ /^no features/);

$layer = Geo::Raster->new(filename => 't/data/test.png');
$gis->add_layer($layer, 'test');

$a = Geo::Raster->new(10,10);
$gis->add_layer($a, 'test2');

$layer->open_symbols_dialog($gis)->destroy;
ok(1);
$layer->open_colors_dialog($gis)->destroy;
ok(1);
$layer->open_labeling_dialog($gis)->destroy;
ok(1);
$a->open_properties_dialog($gis)->destroy;
ok(1);
$layer->open_properties_dialog($gis)->destroy;
ok(1);
$layer->open_copy_dialog($gis)->destroy;
ok(1);
$layer->open_polygonize_dialog($gis)->destroy;
ok(1);

$gis->close();
exit;

sub setup{
    my %params = @_;

    my $window = Gtk2::Window->new;
    
    $window->set_title($params{title})
	if $params{title};
    
    $window->set_default_icon_from_file($params{icon}) 
	if $params{icon} and -f $params{icon};
    
    my $gis = Gtk2::Ex::Geo::Glue->new( main_window => $window );
    
    for (@{$params{classes}}) {
	$gis->register_class($_);
    }

    # layer list
    my $list = Gtk2::ScrolledWindow->new();
    $list->set_policy("never", "automatic");
    $list->add($gis->{tree_view});
    
    # layer list and the map
    my $hbox = Gtk2::HBox->new(FALSE, 0);
    $hbox->pack_start($list, FALSE, FALSE, 0);
    $hbox->pack_start($gis->{overlay}, TRUE, TRUE, 0);
    
    # the stack
    my $vbox = Gtk2::VBox->new(FALSE, 0);
    $vbox->pack_start($gis->{toolbar}, FALSE, FALSE, 0);
    #$vbox->add($hbox);
    $vbox->pack_start($hbox, TRUE, TRUE, 0);
    $vbox->pack_start($gis->{entry}, FALSE, FALSE, 0);
    $vbox->pack_start($gis->{statusbar}, FALSE, FALSE, 0);

    $window->add($vbox);
    $window->signal_connect("destroy", \&close_the_app, [$window, $gis]);
    $window->set_default_size(600,600);
    $window->show_all;
    
    return ($window, $gis);

}

sub close_the_app {
    my($window, $gis) = @{$_[1]};
    $gis->close();
    Gtk2->main_quit;
    exit(0);
}

