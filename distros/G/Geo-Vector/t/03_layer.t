# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gtk2-Ex-Geo.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
use Glib qw/TRUE FALSE/;
BEGIN { 
    use_ok('Geo::Vector');
    use_ok('Gtk2::Ex::Geo');

};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# run as "make test GUI=1" to bring up the GUI

exit unless $ENV{GUI};

Gtk2->init;
Glib->install_exception_handler(\&Gtk2::Ex::Geo::exception_handler);

my($window, $gis) = setup(classes => [qw/Gtk2::Ex::Geo::Layer Geo::Vector::Layer/]);
$gis->add_layer(Geo::Vector->new(features=>[]),'a');
$gis->add_layer(Geo::Vector->new(),'b');

eval {
    require IPC::Gnuplot;
};
unless ($@) {
    my $gnuplot = IPC::Gnuplot->new();
    $gis->register_function( name => 'plot', object => $gnuplot );
    $gis->register_function( name => 'p', object => $gnuplot );
}

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

