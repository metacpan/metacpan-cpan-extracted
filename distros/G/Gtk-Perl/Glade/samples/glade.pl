#!/usr/bin/perl -w

#TITLE: Glade
#REQUIRES: Gtk Glade
use Gtk;
use Gtk::GladeXML;
use Data::Dumper;

eval {
	require Gtk::Gdk::ImlibImage;
	require Gnome;
	init Gnome('glade.pl');
};
init Gtk if $@;

print STDERR "Glade inited\n";

# use new style custom handler.
Gtk::GladeXML->set_custom_handler(\&new_create_custom_widget);
$g = new Gtk::GladeXML(shift || "test.glade");

print "Glade object: ", ref($g),"\n";

#$g->handler_connect('gtk_main_quit', sub {Gtk->main_quit;});
$g->signal_autoconnect_from_package('main');
$w = $g->get_widget('MainWindow');
$button2 = $g->get_widget('button2');
$button2->signal_connect('clicked', sub {
	print "clicked\n";
});

print STDERR "NAME: ", $w->get_name(), "\n" if $w;

main Gtk;

## callbacks..
sub gtk_main_quit {
	print "Test glade quitting\n";
	main_quit Gtk;
}

sub gtk_widget_hide {
	shift->hide();
	1;
}
sub gtk_widget_show {
	my ($w) = shift;
	print STDERR Dumper($w);
	$w->show;
}

# custom widget creation func
sub new_create_custom_widget {
	my $xml = shift;
	my $func_name = shift;
	my @args = @_;
	my $w = new Gtk::Label($args[1])|| die;
	print "New style custom widget got: @args -> $w\n";
	return $w;
}

# custom widget creation func: use the new style instead
sub Gtk::GladeXML::create_custom_widget {
	my @args = @_;
	my $w = new Gtk::Label($args[1])|| die;
	print "custom widget got: @args -> $w\n";
	return $w;
}

