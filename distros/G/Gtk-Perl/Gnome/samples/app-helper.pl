#!/usr/bin/perl -w

#TITLE: Gnome App
#REQUIRES: Gtk Gnome

use strict;
use Gnome;

init Gnome "app-helper", "0.1";
my $app = new Gnome::App "app-helper", "gnome-app-helper test";
signal_connect $app 'delete_event', sub { Gtk->main_quit; return 0 };

my @menu_info = ({type => 'subtree',
		    label => '_File',
		    subtree => [{type => 'subtree',
				 label => '_Foo',
				 pixmap_type => 'stock',
				 pixmap_info => 'Menu_New',
				 subtree => [{type => 'item',
					      label => '_Quux'},
					     {type => 'item',
					      label => '_Argh'}]},
				{type => 'item',
				 label => '_Bar',
				 pixmap_type => 'stock',
				 pixmap_info => 'Menu_About'},
				{type => 'item',
				 label => 'B_az',
				 pixmap_type => 'stock',
				 pixmap_info => 'Menu_Quit',
				 # example code with user data...
				 # note that you get the user data first
				 # and the object last unlike signals...
				 callback => [sub { warn "GOTO DATA: $_[0]\n"; Gtk->main_quit }, "user data"]
				 }]},
		   {type => 'subtree',
		    label => '_Edit',
		    subtree => [{type => 'radioitems',
				 moreinfo => [{type => 'item',
					       label => '_Homer'},
					      {type => 'item',
					       label => '_Marge'}]}]},
		   {type => 'subtree',
		    label => '_Help',
		    subtree => [{type => 'item', label => '_About'}]});

$app->create_menus(@menu_info);

#$app->create_toolbar(
#			{type => 'item', label => 'Fred', callback => sub { Gtk->main_quit },
#		      pixmap_type => 'stock', pixmap_info => 'Quit',
#		      hint => "Click here to quit"},
#		     {type => 'item', label => 'Wilma',
#		      pixmap_type => 'stock', pixmap_info => 'Timer'},
#		     ['item', 'Barney', undef, undef, 'stock', 'About']);

my $toolbar = new Gtk::Toolbar('horizontal', 'text');
$toolbar->set_style('text');
my @toolbar_info = ({type => 'item', label => 'Fred', callback => sub { Gtk->main_quit },
		      pixmap_type => 'stock', pixmap_info => 'Quit',
		      hint => "Click here to quit"},
		     {type => 'item', label => 'Wilma',
		      pixmap_type => 'stock', pixmap_info => 'Timer'},
		     ['item', 'Save', undef, undef, 'filename', 'save.xpm'],
		     ['item', 'Barney', undef, undef, 'stock', 'About']);
$app->fill_toolbar($toolbar, undef, @toolbar_info);
# check if we filled in the widgets correctly
sub show_widget {
	my $item = shift;
	my $subtree;
	if (ref($item) eq 'ARRAY') {
		# we get the widget in the last element
		print "type $item->[0] \"$item->[1]\" -> $item->[-1]\n";
		$subtree = $item->[3] if ($item->[0] eq 'subtree');
	} else { # HASH
		if ($item->{type} eq 'radioitems') {
			$subtree = $item->{'moreinfo'};
		} else {
			print "type $item->{type} \"$item->{label}\" -> $item->{widget}\n";
			$subtree = $item->{'subtree'} if ($item->{'type'} eq 'subtree');
		}
	}
	if (defined $subtree) {
		show_widget($_) foreach @$subtree;
	}
}

show_widget($_) foreach (@toolbar_info, @menu_info);

my $button = $toolbar->append_item('icons', "boh", "bah", undef);
$button->signal_connect('clicked', sub {$toolbar->set_style('icons')});
$app->set_toolbar($toolbar);
show_all $app;
main Gtk;
