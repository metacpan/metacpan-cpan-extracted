use Test::More tests => 1;
use Glib qw/TRUE FALSE/;
use Gtk2;
use Gtk2::Ex::Geo;

BEGIN { 
    use_ok('Gtk2::Ex::Geo::Graph');
};

Gtk2->init;

my($window, $gis) = setup (classes => [qw/Gtk2::Ex::Geo::Layer Gtk2::Ex::Geo::Graph/]);

$gis->{overlay}->signal_connect(update_layers => 
	sub {
	#print STDERR "in callback: @_\n";
	});

exit unless $ENV{GUI};

Gtk2->main;

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
