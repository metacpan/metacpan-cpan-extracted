package Kephra::App::ContextMenu;
our $VERSION = '0.10';

use strict;
use warnings;

sub get{ &Kephra::Menu::ready || Wx::Menu->new() }
#
sub create_all {
	my $config = Kephra::API::settings()->{app}{contextmenu};
	my $default_file = Kephra::Config::filepath($config->{defaultfile});
	my $default_menu_def = Kephra::Config::File::load($default_file);
	unless ($default_menu_def) {
		$default_menu_def = Kephra::Config::Default::contextmenus();
	}

	for my $menu_id (keys %{$config->{id}}){
		if (not ref $menu_id){
			my $start_node = $config->{id}{$menu_id};
			substr($start_node, 0, 1) eq '&'
				? Kephra::Menu::create_dynamic($menu_id, $start_node)
				: do {
					my $menu_def = Kephra::Config::Tree::get_subtree
						($default_menu_def, $start_node);
					Kephra::Menu::create_static ($menu_id, $menu_def);
				}
		} elsif (ref $menu_id eq 'HASH'){
			my $menu = $config->{id}{$menu_id};
			next unless exists $menu->{file};
			my $file_name = $Kephra::temp{path}{config} . $menu->{file};
			next unless -e $file_name;
			my $menu_def = Kephra::Config::File::load($file_name);
			$menu_def = Kephra::Config::Tree::get_subtree($menu_def, $menu->{node});
			Kephra::Menu::create_static($menu_id, $menu_def);
		}
	}
}


# connect the static and build the dynamic
sub connect_all {}
# to editpanel can connect 2 menus, 
sub connect_tabbar {
	my $tabbar = Kephra::App::TabBar::_ref();
	if ( Kephra::App::TabBar::get_contextmenu_visibility() ) {
		connect_widget( $tabbar, Kephra::App::TabBar::_config()->{contextmenu} )
	} else {
		disconnect_widget($tabbar)
	}
}

sub connect_widget {
	my $widget = shift;
	my $menu_id = shift;
	Wx::Event::EVT_RIGHT_DOWN ($widget, sub {
		my ($widget, $event) = @_;
		my $menu = get($menu_id);
		$widget->PopupMenu($menu, $event->GetX, $event->GetY) if Kephra::Menu::is($menu);
	} );
}

sub disconnect_widget{
	my $widget = shift;
	Wx::Event::EVT_RIGHT_DOWN($widget, sub {} ) if substr(ref $widget, 0, 4) eq 'Wx::';
}

1;
