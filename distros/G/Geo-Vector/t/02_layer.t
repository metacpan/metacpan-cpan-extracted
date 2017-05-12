use File::Basename;
use Geo::Vector;
use Gtk2::Ex::Geo;
use Gtk2::TestHelper tests => 13;

my($window, $gis) = setup(classes => [qw/Gtk2::Ex::Geo::Layer Geo::Vector::Layer/]);
ok(1);

my $layer = Geo::Vector::Layer->new(data_source => 't/data/test.shp');
$gis->add_layer($layer, 'test');

$window->show;
ok(1);

$layer->open_symbols_dialog($gis);
ok(1);
$layer->open_colors_dialog($gis);
ok(1);
$layer->open_labeling_dialog($gis);
ok(1);
Geo::Vector::Layer::Dialogs::Properties::open($layer, $gis);
ok(1);
Geo::Vector::Layer::Dialogs::Open::open($gis);
ok(1);
Geo::Vector::Layer::Dialogs::New::open($gis);
ok(1);
Geo::Vector::Layer::Dialogs::Copy::open($layer, $gis);
ok(1);
Geo::Vector::Layer::Dialogs::Rasterize::open($layer, $gis);
ok(1);
Geo::Vector::Layer::Dialogs::Features::open($layer, $gis);
ok(1);
Geo::Vector::Layer::Dialogs::Vertices::open($layer, $gis);
ok(1);
Geo::Vector::Layer::Dialogs::FeatureCollection::open($layer, $gis);
ok(1);

#must examine this more...
#eval {
#    $gis->run_command('open');
#};
#ok($@ =~ /^Can't open data source/, "open fails: $@");
#ok((not $@), "open fails: $@");

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


