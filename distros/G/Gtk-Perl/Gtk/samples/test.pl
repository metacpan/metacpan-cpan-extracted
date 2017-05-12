#!/usr/bin/perl -w

# TITLE: - Gtk widget demo
# REQUIRES: Gtk

# Changes:
# 19980616 PMC <pmc@iskon.hr> clist demo as much as possible like in testgtk
# 19980618 PMC <pmc@iskon.hr> tree demo synced with testgtk

use Gtk;
use Gtk::Atoms;

use strict 'vars';

init Gtk;

# test.pl global variables

my $gtk_1_0 = (Gtk->major_version < 1 or (Gtk->major_version == 1 and Gtk->minor_version < 1));
my $gtk_1_1 = (Gtk->major_version < 1 or (Gtk->major_version == 1 and Gtk->minor_version < 2));

my $cursors_window;
my $button_box_window;
my $spinner_window;
my $wmhints_window;
my $buttons_window;
my $tb_window;
my $cb_window;
my $rb_window;
my $toolbar_window;
my $tree_mode_window;
my $handlebox_window;
my $statusbar_window;
my $reparent_window;
my $pixmap_window;
my $tt_window;
my $s_window;
my $entry_window;
my $list_window;
my $clist_window;
my $ctree_window;
my $menu_window;
my $cs_window;
my $fs_window;
my $font_window;
my $range_window;
my $ruler_window;
my $text_window;
my $paned_window;
my $p_window;
my $cp_window;
my $gp_window;
my $curve_window;
my $scroll_window;
my $dialog_window;
my $sel_window;
my $timeout_window;
my $idle_window;
my $item_factory_window;
my $mainloop_window;

# pixmap cache variables

my @book_open_xpm = (
"16 16 4 1",
"       c None s None",
".      c black",
"X      c #808080",
"o      c white",
"                ",
"  ..            ",
" .Xo.    ...    ",
" .Xoo. ..oo.    ",
" .Xooo.Xooo...  ",
" .Xooo.oooo.X.  ",
" .Xooo.Xooo.X.  ",
" .Xooo.oooo.X.  ",
" .Xooo.Xooo.X.  ",
" .Xooo.oooo.X.  ",
"  .Xoo.Xoo..X.  ",
"   .Xo.o..ooX.  ",
"    .X..XXXXX.  ",
"    ..X.......  ",
"     ..         ",
"                ");

my @book_closed_xpm = (
"16 16 6 1",
"       c None s None",
".      c black",
"X      c red",
"o      c yellow",
"O      c #808080",
"#      c white",
"                ",
"       ..       ",
"     ..XX.      ",
"   ..XXXXX.     ",
" ..XXXXXXXX.    ",
".ooXXXXXXXXX.   ",
"..ooXXXXXXXXX.  ",
".X.ooXXXXXXXXX. ",
".XX.ooXXXXXX..  ",
" .XX.ooXXX..#O  ",
"  .XX.oo..##OO. ",
"   .XX..##OO..  ",
"    .X.#OO..    ",
"     ..O..      ",
"      ..        ",
"                ");

my @mini_page_xpm = (
"16 16 4 1",
"       c None s None",
".      c black",
"X      c white",
"o      c #808080",
"                ",
"   .......      ",
"   .XXXXX..     ",
"   .XoooX.X.    ",
"   .XXXXX....   ",
"   .XooooXoo.o  ",
"   .XXXXXXXX.o  ",
"   .XooooooX.o  ",
"   .XXXXXXXX.o  ",
"   .XooooooX.o  ",
"   .XXXXXXXX.o  ",
"   .XooooooX.o  ",
"   .XXXXXXXX.o  ",
"   ..........o  ",
"    oooooooooo  ",
"                ");

my $book_open;
my $book_open_mask;

my $book_closed;
my $book_closed_mask;

my $mini_page;
my $mini_page_mask;

my $root_win;
my $modeller;
my $sheets;
my $rings;

sub build_option_menu {
	my ( $items, $function, $num_items, $history, $data ) = @_;

	my $omenu = new Gtk::OptionMenu;
	my $menu = new Gtk::Menu;
	my $previous = undef;
	my $i;
    my $menu_item;

	for $i ( 0 .. $num_items - 1 ) {

# Perl/GTK!
# Please note the use of $previous to create the group of radioitems

		$menu_item = new_with_label Gtk::RadioMenuItem( @{$items}[$i], $previous );

		$menu_item->signal_connect( 'activate', $function, $data );
		$menu->append( $menu_item );
		if ( $i == $history ) {
			$menu_item->set_active( 1 );
		}
		$menu_item->show;
		$previous = $menu_item;
	}
	$omenu->set_menu( $menu );
	$omenu->set_history( $history );

	return $omenu;

}

sub find_radio_menu_toggled {
	my ( $widget ) = @_;

	my @group = $widget->group();
	my $i = 0;
	my $item;

	for $item ( @group ) {
		if ( $item->active ) {
			last;
		}
		$i++;
	}

	return $i;
}

sub bbox_widget_destroy {
	my($widget, $todestroy) = @_;
	
}

sub destroy_tooltips {
#	print "Destroy_tooltips: ", Dumper(\@_);
	my($widget, $window) = @_;
	#$$window->{tooltips}->unref;
	$$window = undef;
}

sub set_cursor {
	my($spinner, $widget) = @_;
	my($c, $cursor);
	
	$c = $spinner->get_value_as_int;
	$c = 0 if $c < 0;
	$c = 152 if $c > 152;
	
	$cursor = new Gtk::Gdk::Cursor $c;
	$widget->window->set_cursor($cursor);
	
}

sub cursor_expose_event {
	my($widget) = @_;
	my($drawable) = $widget->window;
	my($white_gc) = $widget->style->white_gc;
	my($gray_gc) = $widget->style->bg_gc('normal');
	my($black_gc) = $widget->style->black_gc;
	
	my($width) = $widget->allocation->[2];
	my($height) = $widget->allocation->[3];
	
	$drawable->draw_rectangle($white_gc, 1, 0, 0, $width, $height / 2);
	$drawable->draw_rectangle($black_gc, 1, 0, $height/2, $width, $height/2);
	$drawable->draw_rectangle($gray_gc, 1, $width/3, $height/3, $width/3, $height/3);
	
	return 1;
}

sub cursor_event {
	my($widget,$spinner, $event) = @_;
	if ($event->{type} =~ /button[-_]press/ and ($event->{button} == 1 or $event->{button} == 3)) {
		$spinner->spin(($event->{button} == 1) ? 'up' : 'down', $spinner->get_adjustment->step_increment);
		return 1;
	}
	return 0;
}

sub create_cursors
{
	if (not defined $cursors_window) {
		$cursors_window = new Gtk::Window -toplevel;
		
		$cursors_window->signal_connect(destroy => \&Gtk::Widget::destroyed, \$cursors_window);
		$cursors_window->set_title("Cursors");
		
		my($main_vbox) = new Gtk::VBox 0, 5;
		border_width $main_vbox 0;
		$cursors_window->add($main_vbox);
		
		my($vbox) = new Gtk::Widget 'Gtk::VBox',
									homogeneous => 0,
									spacing => 5,
									border_width => 10,
									parent => $main_vbox,
									visible => 1;
		
		my($hbox) = new Gtk::HBox 0, 0;
		$hbox->border_width(5);
		$vbox->pack_start($hbox, 0, 1, 0);
		
		my($label) = new Gtk::Label "Cursor Value:";
		$label->set_alignment(0, 0.5);
		$hbox->pack_start($label, 0, 1, 0);
		
		my($adj) = new Gtk::Adjustment 0,	0, 152,	2,	10,	0;
		
		my($spinner) = new Gtk::SpinButton $adj, 0, 0;
		
		$hbox->pack_start($spinner, 1, 1, 0);
		
		my($frame) = new Gtk::Widget 'Gtk::Frame',
									#shadow => 'etched_in',
									label_xalign => 0.5,
									label => "Cursor Area",
									border_width => 10,
									parent => $vbox,
									visible => 1;

		# FIXME		
		$frame->set_shadow_type('etched_in');
		
		my($darea) = new Gtk::DrawingArea;
		
		$darea->set_usize(80,80);
		$frame->add($darea);
		
		$darea->signal_connect(expose_event => \&cursor_expose_event);
		$darea->signal_connect(button_press_event => \&cursor_event, $spinner);
		$darea->set_events(['exposure_mask', 'button_press_mask']);
		show $darea;
		
		signal_connect $spinner "changed" => \&set_cursor, $darea;
		
		my($any) = new Gtk::Widget "Gtk::HSeparator",
									visible => 1;
								
		$main_vbox->pack_start($any, 0, 1, 0);
		
		$hbox = new Gtk::HBox(0, 0);
		$hbox->border_width(10);
		$main_vbox->pack_start($hbox, 0, 1, 0);
		
		my($button) = new Gtk::Button "Close";
		signal_connect $button "clicked" => sub {destroy $cursors_window};
		$hbox->pack_start($button, 1, 1, 5);
		
		show_all $cursors_window;
		
		set_cursor ($spinner, $darea);
		
	} else {
		destroy $cursors_window;
	}
}

sub create_bbox_window {
	my($horizontal, $title, $pos, $spacing, $child_w, $child_h, $layout) = @_;
	my($window, $box1, $bbox, $button);
	
	$window = new Gtk::Window -toplevel;
	set_title $window $title;
	
	$window->signal_connect("destroy", \&bbox_widget_destroy, \$window);
	
	if ($horizontal) {
		set_usize $window 550, 60;
		set_uposition $window 150, $pos;
		$box1 = new Gtk::VBox 0, 0;
	} else {
		set_usize $window 150, 400;
		set_uposition $window $pos, 200;
		$box1 = new Gtk::VBox 0, 0;
	}
	
	add $window $box1;
	show $box1;
	
	if ($horizontal) {
		$bbox = new Gtk::HButtonBox;
	} else {
		$bbox = new Gtk::VButtonBox;
	}
	
	set_layout $bbox $layout;
	set_spacing $bbox $spacing;
	set_child_size $bbox $child_w, $child_h;
	show $bbox;
	
	border_width $box1 25;
	pack_start $box1 $bbox, 1, 1, 0;
	
	$button = new Gtk::Button "OK";
	add $bbox $button;
	signal_connect $button "clicked" => \&bbox_widget_destroy, \$window;
	show $button;
	
	$button = new Gtk::Button "Cancel";
	add $bbox $button;
	show $button;
	
	$button = new Gtk::Button "Help";
	add $bbox $button;
	show $button;
	
	show $window;
}

sub test_hbbox {
	create_bbox_window (1, "Spread", 50, 40, 85, 28, -spread);
	create_bbox_window (1, "Edge", 200, 40, 85, 25, -edge);
	create_bbox_window (1, "Start", 350, 40, 85, 25, -start);
	create_bbox_window (1, "End", 500, 15, 30, 25, -end);
}

sub test_vbbox {
	create_bbox_window (0, "Spread", 50, 40, 85, 28, -spread);
	create_bbox_window (0, "Edge", 250, 40, 85, 28, -edge);
	create_bbox_window (0, "Start", 450, 40, 85, 25, -start);
	create_bbox_window (0, "End", 650, 15, 30, 25, -end);
}

sub create_button_box {
	my($bbox,$button);
	
	if (not defined $button_box_window) {
		$button_box_window = new Gtk::Window -toplevel;
		$button_box_window->set_title("Button Box Test");
		$button_box_window->signal_connect("destroy", \&Gtk::Widget::destroyed, \$button_box_window);
		
		$button_box_window->border_width(20);
		
		$bbox = new Gtk::HButtonBox;
		$button_box_window->add($bbox);
		show $bbox;
		
		$button = new Gtk::Button "Horizontal";
		signal_connect $button "clicked" => \&test_hbbox;
		$bbox->add($button);
		show $button;
		
		$button = new Gtk::Button "Vertical";
		signal_connect $button "clicked" => \&test_vbbox;
		$bbox->add($button);
		show $button;
	}
	
	if (!$button_box_window->visible) {
		show $button_box_window;
	} else {
		destroy $button_box_window;
	}
}

my $spinner1 = undef;

sub toggle_snap {
	my($widget, $spin) = @_;
	
	$spin->set_snap_to_ticks($widget->active);
}

sub toggle_numeric {
	my($widget, $spin) = @_;
	$spin->set_numeric($widget->active);
}

sub change_digits {
	my($widget, $spin) = @_;
	$spinner1->set_digits($spin->get_value_as_int);
}

sub get_value {
	my($widget,$data) = @_;
	my($label, $spin, $buf);
	$spin = $spinner1;
	$label = $widget->{label};
	if ($data == 1) {
		$buf = sprintf "%d", $spin->get_value_as_int;
	} else {
		$buf = sprintf "%0.*f", $spin->digits, $spin->get_value_as_float;
	}
	$label->set($buf);
}

sub create_spins {
	my($frame, $hbox, $main_vbox, $vbox, $vbox2, $spinner2, $spinner, $button, $label, $val_label, $adj);
	
	if (not defined $spinner_window) {
		$spinner_window = new Gtk::Window -toplevel;
		
		$spinner_window->signal_connect(destroy => \&Gtk::Widget::destroyed, \$spinner_window);
		$spinner_window->set_title("GtkSpinButton");
		
		$main_vbox = new Gtk::VBox 0, 5;
		border_width $main_vbox 10;
		$spinner_window->add($main_vbox);
		
		$frame = new Gtk::Frame "Not accelerated";
		$main_vbox->pack_start($frame, 1, 1, 0);
		
		$vbox = new Gtk::VBox 0, 0;
		$vbox->border_width(5);
		$frame->add($vbox);
		
		$hbox = new Gtk::HBox(0,0);
		$vbox->pack_start($hbox, 1, 1, 5);
		
		$vbox2 = new Gtk::VBox(0,0);
		$hbox->pack_start($vbox2, 1, 1, 5);
		
		$label = new Gtk::Label "Day :";
		$label->set_alignment(0, 0.5);
		$vbox2->pack_start($label, 0, 1, 0);
		
		$adj = new Gtk::Adjustment 1.0, 1.0, 31.0, 1.0, 5.0, 0.0;
		
		$spinner = new Gtk::SpinButton $adj, 0, 0;
		$spinner->set_wrap(1);
		$vbox2->pack_start($spinner, 0, 1, 0);
		
		$vbox2 = new Gtk::VBox 0, 0;
		$hbox->pack_start($vbox2, 1, 1, 5);
		
		$label = new Gtk::Label "Month :";
		$label->set_alignment(0, 0.5);
		$vbox2->pack_start($label, 0, 1, 0);
		
		$adj = new Gtk::Adjustment 1.0, 1.0, 12.0, 1.0, 5.0, 0.0;
		
		$spinner = new Gtk::SpinButton $adj, 0, 0;
		$spinner->set_wrap(1);
		$vbox2->pack_start($spinner, 0, 1, 0);
		
		$vbox2 = new Gtk::VBox 0, 0;
		$hbox->pack_start($vbox2, 1, 1, 5);
		
		$label = new Gtk::Label "Year :";
		$label->set_alignment(0, 0.5);
		$vbox2->pack_start($label, 0, 1, 0);
		
		$adj = new Gtk::Adjustment 1998.0, 0.0, 2100.0, 1.0, 100.0, 0.0;
		
		$spinner = new Gtk::SpinButton $adj, 0, 0;
		$spinner->set_wrap(1);
		$spinner->set_usize(55, 0);
		$vbox2->pack_start($spinner, 0, 1, 0);
		
		$frame = new Gtk::Frame "Accelerated";
		$main_vbox->pack_start($frame, 1, 1, 0);
		
		$vbox = new Gtk::VBox 0, 0;
		$vbox->border_width(5);
		$frame->add($vbox);
		
		$hbox = new Gtk::HBox 0, 0;
		$vbox->pack_start($hbox, 0, 1, 5);
		
		$vbox2 = new Gtk::VBox 0, 0;
		$hbox->pack_start($vbox2, 1, 1, 5);
		
		$label = new Gtk::Label "Value :";
		$label->set_alignment(0, 0.5);
		$vbox2->pack_start($label, 0, 1, 0);
		
		$adj = new Gtk::Adjustment 0.0, -10000.0, 10000.0, 0.5, 100.0, 0.0;
		$spinner1 = new Gtk::SpinButton $adj, 1.0, 2;
		$spinner1->set_wrap(1);
		$spinner1->set_usize(100, 0);
		$spinner1->set_update_policy('always');
		$vbox2->pack_start($spinner1, 0, 1, 0);
		
		$vbox2 = new Gtk::VBox 0, 0;
		$hbox->pack_start($vbox2, 1, 1, 5);
		
		$label = new Gtk::Label "Digits :";
		$label->set_alignment(0, 0.5);
		$vbox2->pack_start($label, 0, 1, 0);
		
		$adj = new Gtk::Adjustment(2, 1, 5, 1, 1, 0);
		$spinner2 = new Gtk::SpinButton($adj, 0.0, 0);
		$spinner2->set_wrap(1);
		$adj->signal_connect(value_changed => \&change_digits, $spinner2);
		$vbox2->pack_start($spinner2, 0, 1, 0);
		
		$hbox = new Gtk::HBox(0, 0);
		$vbox->pack_start($hbox, 0, 1, 5);
		
		$button = new Gtk::CheckButton "Snap to 0.5-ticks";
		$button->signal_connect(clicked => \&toggle_snap, $spinner1);
		$vbox->pack_start($button, 1, 1, 0);
		$button->set_active(1);
		
		$button = new Gtk::CheckButton "Numeric only input mode";
		$button->signal_connect(clicked => \&toggle_numeric, $spinner1);
		$vbox->pack_start($button, 1, 1, 0);
		$button->set_active(1);
		
		$val_label = new Gtk::Label "";
		
		$hbox = new Gtk::HBox 0, 0;
		$vbox->pack_start($hbox, 0, 1, 5);
		
		$button = new Gtk::Button "Value as Int";
		$button->{label} = $val_label;
		$button->signal_connect(clicked => \&get_value, 1);
		$hbox->pack_start($button, 1, 1, 5);
		
		$button = new Gtk::Button "Value as Float";
		$button->{label} = $val_label;
		$button->signal_connect(clicked => \&get_value, 2);
		$hbox->pack_start($button, 1, 1, 5);
		
		$vbox->pack_start($val_label, 1, 1, 0);
		$val_label->set("0");
		
		$hbox = new Gtk::HBox 0, 0;
		$main_vbox->pack_start($hbox, 0, 1, 0);
		
		$button = new Gtk::Button "Close";
		$button->signal_connect(clicked => sub {destroy $spinner_window});
		$hbox->pack_start($button, 1, 1, 5);
		
	}
	
	if (!$spinner_window->visible) {
		show_all $spinner_window;
	} else {
		destroy $spinner_window;
	}
}


sub shape_pressed {
	my($widget, $event) = @_;

	return 0 if $event->{type} !~ /button[-_]press/;

	my($w);
	
	$widget->{save_x} = $event->{'x'};
	$widget->{save_y} = $event->{'y'};
	$widget->{in_grab} = 1;

	$widget->grab_add;
	$w = $widget->window;
	Gtk::Gdk->pointer_grab($w, 1, 
		['button_release_mask', 'button_motion_mask', 'pointer_motion_hint_mask'], 
		undef, undef ,0);
	return 1;
}

sub shape_released {
	my($widget) = @_;
	$widget->{in_grab} = 0;
	$widget->grab_remove;
	Gtk::Gdk->pointer_ungrab(0);
	return 1;
}

sub shape_motion {
	my($widget, $event) = @_;

	return 0 unless $widget->{in_grab};
	my ($x, $y) = $root_win->get_pointer;
	$widget->set_uposition($x - $widget->{save_x}, $y - $widget->{save_y});
	return 1;
}


sub shape_create_icon {
	my($xpm_file, $x, $y, $px, $py, $window_type) = @_;
	my($window, $pixmap, $fixed, $gc, $gdk_pixmap_mask, $gdk_pixmap, $style);
	
	$style = Gtk::Widget->get_default_style;
	$gc = $style->black;#_gc;
	
	$window = new Gtk::Window $window_type;
	
	$fixed = new Gtk::Fixed;
	$fixed->set_usize(100,100);
	$window->add($fixed);
	show $fixed;
	
	$window->set_events( [keys %{$window->get_events}, 'button_motion_mask', 'pointer_motion_hint_mask', 'button_press_mask']);
	
	realize $window;
	
	($gdk_pixmap, $gdk_pixmap_mask) = Gtk::Gdk::Pixmap->create_from_xpm($window->window, $style->bg('normal'), $xpm_file);
	
	$pixmap = new Gtk::Pixmap $gdk_pixmap, $gdk_pixmap_mask;
	$fixed->put($pixmap, $px, $py);
	show $pixmap;
	
	$window->shape_combine_mask($gdk_pixmap_mask, $px, $py);
	
	$window->signal_connect('button_press_event', \&shape_pressed);
	$window->signal_connect('button_release_event', \&shape_released);
	$window->signal_connect('motion_notify_event', \&shape_motion);
	
	$window->set_uposition($x,$y);
	$window->show;
	
	$window;
}


sub destroy_window {
	my($widget, $windowref, $w2) = @_;
	$$windowref = undef;
	$w2 = undef if defined $w2;
	0;
}

sub button_window {
	my($widget,$button) = @_;
	if (! $button->visible) {
		show $button;
	} else {
		hide $button;
	}
}

sub create_shapes {
	
	$root_win = Gtk::Gdk::Window->new_foreign(Gtk::Gdk->ROOT_WINDOW());
	
	if (not defined $modeller) {
		$modeller = shape_create_icon("xpm/Modeller.xpm", 440, 140, 0,0, -popup);
		$modeller->signal_connect("destroy", \&Gtk::Widget::destroyed, \$modeller);
	} else {
		destroy $modeller;
	}

	if (not defined $sheets) {
		$sheets = shape_create_icon("xpm/FilesQueue.xpm", 580,170, 0,0, -popup);
		$sheets->signal_connect("destroy", \&Gtk::Widget::destroyed, \$sheets);
	} else {
		destroy $sheets;
	}

	if (not defined $rings) {
		$rings = shape_create_icon("xpm/3DRings.xpm", 460, 270, 25,25, -toplevel);
		$rings->signal_connect("destroy", \&Gtk::Widget::destroyed, \$rings);
	} else {
		destroy $rings;
	}
}

sub create_wmhints {
	my($circles,$mask,$box1,$box2,$separator,$label,$button);
	
	if (not defined $wmhints_window) {
		$wmhints_window = new Gtk::Window 'toplevel';
		signal_connect $wmhints_window "destroy", \&destroy_window, \$wmhints_window;
		signal_connect $wmhints_window "delete_event", \&destroy_window, \$wmhints_window;
		$wmhints_window->set_title("WM Hints");
		$wmhints_window->border_width(0);
		
		$wmhints_window->realize;
		
		($circles,$mask) = Gtk::Gdk::Pixmap->create_from_xpm($wmhints_window->window, $wmhints_window->style->white, "xpm/circles.xpm");
		
		$wmhints_window->window->set_icon(undef, $circles, $mask);

		$wmhints_window->window->set_icon_name("WMHints Test Icon");
		
		$wmhints_window->window->set_decorations(['all', 'menu']);
		$wmhints_window->window->set_functions(['all', 'resize']);

		$box1 = new Gtk::VBox 0, 0;
		$wmhints_window->add($box1);
		$box1->show;
		
		$label = new Gtk::Label "Try iconizing me!";
		$label->set_usize(150,50);
		$box1->pack_start($label, 1, 1, 0);
		$label->show;
		
		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);
		$separator->show;
		
		$box2 = new Gtk::VBox 0, 10;
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;
		
		$button = new Gtk::Button "close";
		
		$button->signal_connect( clicked => sub {destroy $wmhints_window});
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default();
		$button->show;
	}
	if (not $wmhints_window->visible) {
		$wmhints_window->show;
	} else {	
		destroy $wmhints_window;
	}
}


sub create_buttons {
	my($box1, $box2, $table, @button, $separator);
	
	if (not defined $buttons_window) {
		$buttons_window = new Gtk::Window 'toplevel';
		signal_connect $buttons_window "destroy", \&destroy_window, \$buttons_window;
		signal_connect $buttons_window "delete_event", \&destroy_window, \$buttons_window;
		$buttons_window->set_title("buttons");
		$buttons_window->border_width(0);
	
		$box1 = new Gtk::VBox 0, 0;
		$buttons_window->add($box1);
		$box1->show;
		
		$table = new Gtk::Table (3,3, 0);
		$table->set_row_spacings(5);
		$table->set_col_spacings(5);
		$table->border_width(10);
		$box1->pack_start($table, 1, 1, 0);
		$table->show;
		
		for (0..8) { $button[$_] = new Gtk::Button "button".($_+1); }
		
		$button[0]->signal_connect("clicked", \&button_window, $button[1]);
		$table->attach($button[0], 0, 1, 0, 1, {expand=>1,fill=>1}, {expand=>1,fill=>1},0,0);
		$button[0]->show;

		$button[1]->signal_connect("clicked", \&button_window, $button[2]);
		$table->attach($button[1], 1, 2, 1, 2, {expand=>1,fill=>1}, {expand=>1,fill=>1},0,0);
		$button[1]->show;

		$button[2]->signal_connect("clicked", \&button_window, $button[3]);
		$table->attach($button[2], 2, 3, 2, 3, ["expand","fill"], ["expand","fill"],0,0);
		$button[2]->show;

		$button[3]->signal_connect("clicked", \&button_window, $button[4]);
		$table->attach($button[3], 0, 1, 2, 3, ["expand","fill"], ["expand","fill"],0,0);
		$button[3]->show;

		$button[4]->signal_connect("clicked", \&button_window, $button[5]);
		$table->attach($button[4], 2, 3, 0, 1, ["expand","fill"], ["expand","fill"],0,0);
		$button[4]->show;

		$button[5]->signal_connect("clicked", \&button_window, $button[6]);
		$table->attach($button[5], 1, 2, 2, 3, ["expand","fill"], ["expand","fill"],0,0);
		$button[5]->show;

		$button[6]->signal_connect("clicked", \&button_window, $button[7]);
		$table->attach($button[6], 1, 2, 0, 1, ["expand","fill"], ["expand","fill"],0,0);
		$button[6]->show;

		$button[7]->signal_connect("clicked", \&button_window, $button[8]);
		$table->attach($button[7], 2, 3, 1, 2, ["expand","fill"], ["expand","fill"],0,0);
		$button[7]->show;

		$button[8]->signal_connect("clicked", \&button_window, $button[8]);
		$table->attach($button[8], 0, 1, 1, 2, ["expand","fill"], ["expand","fill"],0,0);
		$button[8]->show;
		
		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);
		$separator->show;
		
		$box2 = new Gtk::VBox(0, 10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;
		
		$button[0] = new Gtk::Button "close";
		$button[0]->signal_connect("clicked", sub { destroy $buttons_window});
		$box2->pack_start($button[0], 1, 1, 0);
		$button[0]->can_default(1);
		$button[0]->grab_default;
		$button[0]->show;
	}
	if (not $buttons_window->visible) {
		$buttons_window->show;
	} else {	
		destroy $buttons_window;
	}
}

sub create_toggle_buttons {
	my($box1, $box2, $button, $separator);
	if (not defined $tb_window) {
		$tb_window = new Gtk::Window -toplevel;
		$tb_window->signal_connect("destroy", \&destroy_window, \$tb_window);
		$tb_window->signal_connect("delete_event", \&destroy_window, \$tb_window);
		$tb_window->set_title("toggle buttons");
		$tb_window->border_width(0);
		
		$box1 = new Gtk::VBox(0, 0);
		$tb_window->add($box1);
		$box1->show;
		
		$box2 = new Gtk::VBox 0, 10;
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;
		
		$button = new Gtk::ToggleButton "button1";
		$box2->pack_start($button, 1, 1, 0);
		$button->show;
		
		$button = new Gtk::ToggleButton "button2";
		$box2->pack_start($button, 1, 1, 0);
		$button->show;
		
		$button = new Gtk::ToggleButton "button3";
		$box2->pack_start($button, 1, 1, 0);
		$button->show;
		
		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);
		$separator->show;
		
		$box2 = new Gtk::VBox (0, 10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;
		
		$button = new Gtk::Button "close";
		$button->signal_connect( "clicked", sub { destroy $tb_window });
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;
		$button->show;
	}
	
	if (!$tb_window->visible) {
		$tb_window->show;
	} else {
		destroy $tb_window;
	}
}

sub create_check_buttons {
	my($box1, $box2, $button, $separator);
	if (not defined $cb_window) {
		$cb_window = new Gtk::Window -toplevel;
		$cb_window->signal_connect('destroy', \&destroy_window, \$cb_window);
		$cb_window->signal_connect('delete_event', \&destroy_window, \$cb_window);
		$cb_window->set_title('check buttons');
		$cb_window->border_width(0);
		
		$box1 = new Gtk::VBox 0, 0;
		$cb_window->add($box1);
		$box1->show;
		
		$box2 = new Gtk::VBox 0, 10;
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;
		
		$button = new Gtk::CheckButton 'button1';
		$box2->pack_start($button, 1, 1, 0);
		$button->show;
		
		$button = new Gtk::CheckButton 'button2';
		$box2->pack_start($button, 1, 1, 0);
		$button->show;
		
		$button = new Gtk::CheckButton 'button3';
		$box2->pack_start($button, 1, 1, 0);
		$button->show;
		
		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);
		$separator->show;
		
		$box2 = new Gtk::VBox 0, 10;
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;
		
		$button = new Gtk::Button 'close';
		$button->signal_connect( 'clicked', sub {destroy $cb_window });
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;
		$button->show;
	}
	
	if (!$cb_window->visible) {
		$cb_window->show;
	} else {
		destroy $cb_window;
	}
}

sub create_radio_buttons {
	my($box1,$box2,$button,$separator);
	
	if (not defined $rb_window) {
		$rb_window = new Gtk::Window -toplevel;
		$rb_window->signal_connect("destroy", \&destroy_window, \$rb_window);
		$rb_window->signal_connect("delete_event", \&destroy_window, \$rb_window);
		$rb_window->set_title("radio buttons");
		$rb_window->border_width(0);

		$box1 = new Gtk::VBox(0,0);
		$rb_window->add($box1);
		show $box1;

		$box2 = new Gtk::VBox(0,10);
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;

		$button = new Gtk::RadioButton "button1";
		$box2->pack_start($button, 1, 1, 0);
		$button->show;
		
		$button = new Gtk::RadioButton "button2", $button;
		$button->set_active(1);
		$box2->pack_start($button, 1, 1, 0);
		$button->show;

		$button = new Gtk::RadioButton "button3", $button;
		$box2->pack_start($button, 1, 1, 0);
		$button->show;

		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);
		$separator->show;
		
		$box2 = new Gtk::VBox(0,10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;
		
		$button = new Gtk::Button "close";
		$button->signal_connect( clicked => sub { destroy $rb_window} );
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;
		$button->show;
	}
	
	if (!$rb_window->visible) {
		show $rb_window;
	} else {
		destroy $rb_window;
	}
}

sub new_pixmap {
	my ($filename, $window, $background) = @_;
	my ($pixmap, $mask) = create_from_xpm Gtk::Gdk::Pixmap($window, $background, $filename);

	return new Gtk::Pixmap($pixmap, $mask);
}

sub create_toolbar_window {
	my ($toolbar, $button, $window, $color);

	if (!defined $toolbar_window ) {
		$toolbar_window = new Gtk::Window "toplevel";
		$toolbar_window->signal_connect("destroy", \&destroy_window, \$toolbar_window);
		$toolbar_window->signal_connect("delete_event", \&destroy_window, \$toolbar_window);
		$toolbar_window->set_title("toolbar");
		$toolbar_window->border_width(0);

		$toolbar_window->realize;

		$toolbar = make_toolbar($toolbar_window);
		$toolbar_window->add($toolbar);
		$toolbar->show;
	}

	if (!$toolbar_window->visible) {
		show $toolbar_window;
	} else {
		destroy $toolbar_window;
	}
}


sub make_toolbar {
	my ($toplevel) = shift;
	my ($window, $color, $toolbar, $button, $entry);

	$toplevel->realize unless $toplevel->realized;

	$window = $toplevel->window;
	$color = $toplevel->style->bg('normal');
	
	$toolbar = new Gtk::Toolbar('horizontal', 'both');
	$toolbar->set_space_style('line');
	$toolbar->set_button_relief("none");
	$button = $toolbar->append_item ( "Horizontal", "Horizontal toolbar layout",
		"Toolbar/Horizontal", new_pixmap("xpm/test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_orientation('horizontal')});
	$button = $toolbar->append_item( "Vertical","Vertical toolbar layout",
		"Toolbar/Vertical", new_pixmap("xpm/test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_orientation('vertical')});

	$toolbar->append_space();

	$button = $toolbar->append_item( "Icons","Only show toolbar icons",
		"Toolbar/IconsOnly", new_pixmap("xpm/test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_style('icons')});
	$button = $toolbar->append_item( "Text","Only show toolbar text",
		"Toolbar/TextOnly", new_pixmap("xpm/test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_style('text')});
	$button = $toolbar->append_item( "Both","Show toolbar icons and text",
		"Toolbar/Both", new_pixmap("xpm/test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_style('both')});

	$toolbar->append_space;

	$entry = new Gtk::Entry;
	$entry->set_text("Abracadabra");
	$entry->set_max_length(3);
	$entry->show;
	$toolbar->append_widget($entry, "This is an unusable GtkEntry ;)", "Hey don't click me!!!");

	$button = $toolbar->append_item( "Small","Use small spaces",
		"Toolbar/Small",, new_pixmap("xpm/test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_space_size(5)});
	$button = $toolbar->append_item( "Big","Use big spaces",
		"Toolbar/Big", new_pixmap("xpm/test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_space_size(10)});

	$toolbar->append_space();

	$button = $toolbar->append_item( "Enable","Enable tooltips",
		undef, new_pixmap("xpm/test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_tooltips(1)});
	$button = $toolbar->append_item( "Disable","Disable tooltips",
		undef, new_pixmap("xpm/test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_tooltips(0)});

	$toolbar;
}

my $tree_default_items = 3.0;
my $tree_default_depth = 3.0;

my $tree_single_button;
my $tree_browse_button;
my $tree_multiple_button;

my $tree_draw_line_button;
my $tree_view_line_button;
my $tree_without_root_button;

my $tree_items_spinner;
my $tree_depth_spinner;

my $tree_add_button;
my $tree_remove_button;
my $tree_subtree_button;

my $tree_nb_item_add = 1;

sub cb_add_new_item
{
	my($widget, $tree)=@_;
	my(@selected_list, $subtree, $selected_item, $item_new);

	@selected_list=$tree->selection;
	if($#selected_list == -1 ) {
		$subtree=$tree;
	} else {
		$selected_item=$selected_list[0];
		$subtree=$selected_item->subtree;
		if(not defined $subtree) {
			$subtree = new Gtk::Tree;
			$selected_item->set_subtree($subtree);
		}
	}
	$item_new = new_with_label Gtk::TreeItem "item add $tree_nb_item_add";
	$subtree->append($item_new);
	$item_new->show;
	$tree_nb_item_add++;
}

sub cb_remove_item
{
	my($widget, $tree)=@_;
	my(@selected_list);

	@selected_list=$tree->selection;
	$tree->remove_items(@selected_list);
}

sub cb_remove_subtree
{
	my($widget, $tree)=@_;
	my(@selected_list, $item);

	@selected_list=$tree->selection;
	if($#selected_list != -1) {
		$item=$selected_list[0];
		if(defined $item->subtree){
			$item->remove_subtree;
		}
	}
}

sub cb_tree_changed
{
	my($tree)=@_;
	my(@selected_list, $nb_selected);

	@selected_list=$tree->selection;
	$nb_selected=$#selected_list + 1;
	if ( $nb_selected == 0 ) {
		if (not defined $tree->children ) {
			$tree_add_button->set_sensitive(1);
		} else {
			$tree_add_button->set_sensitive(0);
		}
		$tree_remove_button->set_sensitive(0);
		$tree_subtree_button->set_sensitive(0);
	} else {
		$tree_remove_button->set_sensitive(1);
		$tree_add_button->set_sensitive($nb_selected == 1);
		$tree_subtree_button->set_sensitive($nb_selected == 1);
	}
}

sub create_subtree
{
	my($item, $level, $nb_item_max, $recursion_level_max) = @_;

	my(
		$item_subtree,
		$item_new,
		$nb_item,
		$no_root_item
	);

	if ( $level == $recursion_level_max ) {
		return;
	};
	if ( $level == -1 ) {
		$level = 0;
		$item_subtree = $item;
		$no_root_item = 1;
	} else {
		$item_subtree = new Gtk::Tree;
		$no_root_item = 0;
	}
	for $nb_item ( 0 .. $nb_item_max - 1 ) {
		$item_new = new_with_label Gtk::TreeItem "item $level - $nb_item";
		$item_subtree->append($item_new);
		create_subtree($item_new, $level + 1, $nb_item_max, $recursion_level_max);
		$item_new->show;
	}
	if (not $no_root_item ) {
		$item->set_subtree($item_subtree);
	}
}

sub create_tree_sample
{
	my($selection_mode, $draw_line, $view_line, $no_root_item, $nb_item_max, $recursion_level_max) = @_;

	my(
		$tree_sample_window,
		$box1,
		$box2,
		$separator,
		$button,
		$scrolled_win,
		$root_tree,
		$root_item
	);

	$tree_sample_window = new Gtk::Window -toplevel;
	$tree_sample_window->signal_connect('destroy', \&destroy_window, \$tree_sample_window);
	$tree_sample_window->signal_connect('delete_event', \&destroy_window, \$tree_sample_window);
	$tree_sample_window->set_title('Tree Sample');
	$tree_sample_window->border_width(0);

	$box1 = new Gtk::VBox 0, 0;
	$tree_sample_window->add($box1);
	$box1->show;

	$box2 = new Gtk::VBox 0, 0;
	$box2->border_width(5);
	$box1->pack_start($box2, 1, 1, 0);
	$box2->show;

	$scrolled_win = new Gtk::ScrolledWindow(undef, undef);
	$scrolled_win->set_policy('automatic', 'automatic');
	$scrolled_win->set_usize(200, 200);
	$box2->pack_start($scrolled_win, 1, 1, 0);
	$scrolled_win->show;

	$root_tree = new Gtk::Tree;
	$root_tree->signal_connect('selection_changed', \&cb_tree_changed);
	$root_tree->set_selection_mode($selection_mode);
	$root_tree->set_view_lines($draw_line);

	if ( $view_line ) {
		$root_tree->set_view_mode('line');
	} else {
		$root_tree->set_view_mode('item');
	}
	$scrolled_win->add_with_viewport($root_tree);
	$root_tree->show;

	if ( $no_root_item ) {
		$root_item = $root_tree;
	} else {
		$root_item = new_with_label Gtk::TreeItem 'root item';
		$root_tree->append($root_item);
		$root_item->show();
	}

	create_subtree($root_item, - $no_root_item, $nb_item_max, $recursion_level_max);

	$box2 = new Gtk::VBox 0, 0;
	$box2->border_width(5);
	$box1->pack_start($box2, 0, 0, 0);
	$box2->show;

	$button = new Gtk::Button 'Add Item';
	$tree_add_button = $button;
	$button->set_sensitive(0);
	$button->signal_connect('clicked', \&cb_add_new_item, $root_tree);
	$box2->pack_start($button, 1, 1, 0);
	$button->show;

	$button = new Gtk::Button 'Remove Item(s)';
	$tree_remove_button = $button;
	$button->set_sensitive(0);
	$button->signal_connect('clicked', \&cb_remove_item, $root_tree);
	$box2->pack_start($button, 1, 1, 0);
	$button->show;

	$button = new Gtk::Button 'Remove Subtree';
	$tree_subtree_button = $button;
	$button->set_sensitive(0);
	$button->signal_connect('clicked', \&cb_remove_subtree, $root_tree);
	$box2->pack_start($button, 1, 1, 0);
	$button->show;

	$separator = new Gtk::HSeparator;
	$box1->pack_start($separator, 0, 0, 0);
	$separator->show;

	$box2 = new Gtk::VBox 0, 0;
	$box2->border_width(5);
	$box1->pack_start($box2, 0, 0, 0);
	$box2->show;

	$button = new Gtk::Button 'Close';
	$button->signal_connect('clicked', sub {destroy $tree_sample_window});
	$box2->pack_start($button, 1, 1, 0);
	$button->show;

	$tree_sample_window->show;
}

sub cb_create_tree
{
	my $selection_mode = 'single';
	my $view_line;
	my $draw_line;
	my $no_root_item;
	my $items;
	my $depth;

	if ( $tree_single_button->active ) {
		$selection_mode = 'single';
	} elsif ( $tree_browse_button->active ) {
		$selection_mode = 'browse';
	} elsif ( $tree_multiple_button->active ) {
		$selection_mode = 'multiple';
	}
	$view_line = $tree_view_line_button->active;
	$draw_line = $tree_draw_line_button->active;
	$items = $tree_items_spinner->get_value_as_int;
	$depth = $tree_depth_spinner->get_value_as_int;
	$no_root_item = $tree_without_root_button->active;

	create_tree_sample($selection_mode, $draw_line, $view_line, $no_root_item, $items, $depth);
}

sub create_tree_mode_window
{
	my ($box1, $box2, $box3, $frame, $box4, $box5, $label, $adj, $spinner, $separator, $button);

	if (not defined $tree_mode_window) {
		$tree_mode_window = new Gtk::Window -toplevel;
    		$tree_mode_window->signal_connect('destroy', \&destroy_window, \$tree_mode_window);
		$tree_mode_window->signal_connect('delete_event', \&destroy_window, \$tree_mode_window);
		$tree_mode_window->set_title("Tree Mode Selection Window");
		$tree_mode_window->border_width(0);

		$box1 = new Gtk::VBox 0, 0;
		$tree_mode_window->add($box1);
		$box1->show;

		$box2 = new Gtk::VBox 0, 5;
		$box2->border_width(5);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;

		$box3 = new Gtk::HBox 0, 5;
		$box2->pack_start($box3, 1, 1, 0);
		$box3->show;

		$frame = new Gtk::Frame 'Selection Mode';
		$box3->pack_start($frame, 1, 1, 0);
		$frame->show;

		$box4 = new Gtk::VBox 0, 0;
		$box4->border_width(5);
		$frame->add($box4);
		$box4->show;

		$button = new Gtk::RadioButton 'SINGLE';
		$tree_single_button = $button;
		$box4->pack_start($button, 1, 1, 0);
		$button->show;

		$button = new Gtk::RadioButton 'BROWSE', $button;
		$tree_browse_button = $button;
		$box4->pack_start($button, 1, 1, 0);
		$button->show;

		$button = new Gtk::RadioButton 'MULTIPLE', $button;
		$tree_multiple_button = $button;
		$box4->pack_start($button, 1, 1, 0);
		$button->show;

		$frame = new Gtk::Frame 'Options';
		$box3->pack_start($frame, 1, 1, 0);
		$frame->show;

		$box4 = new Gtk::VBox 0, 0;
		$box4->border_width(5);
		$frame->add($box4);
		$box4->show;

		$button = new Gtk::CheckButton 'Draw line';
		$tree_draw_line_button = $button;
		$button->set_active(1);
		$box4->pack_start($button, 1, 1, 0);
		$button->show;

		$button = new Gtk::CheckButton 'View line mode';
		$tree_view_line_button = $button;
		$button->set_active(1);
		$box4->pack_start($button, 1, 1, 0);
		$button->show;

		$button = new Gtk::CheckButton 'Without Root item';
		$tree_without_root_button = $button;
		$box4->pack_start($button, 1, 1, 0);
		$button->show;

		$frame = new Gtk::Frame 'Size parameters';
		$box2->pack_start($frame, 1, 1, 0);
		$frame->show;

		$box4 = new Gtk::HBox 0, 5;
		$box4->border_width(5);
		$frame->add($box4);
		$box4->show;

		$box5 = new Gtk::HBox 0, 5;
		$box4->pack_start($box5, 0, 0, 0);
		$box5->show;

		$label = new Gtk::Label 'Number of Items';
		$label->set_alignment(0, 0.5);
		$box5->pack_start($label, 0, 1, 0);
		$label->show;

		$adj = new Gtk::Adjustment $tree_default_items, 1.0, 255.0, 1.0, 5.0, 0.0;

		$spinner = new Gtk::SpinButton $adj, 0, 0;
		$tree_items_spinner = $spinner;
		$box5->pack_start($spinner, 0, 1, 0);
		$spinner->show;

		$box5 = new Gtk::HBox 0, 5;
		$box4->pack_start($box5, 0, 0, 0);
		$box5->show;

		$label = new Gtk::Label 'Depth Level';
		$label->set_alignment(0, 0.5);
		$box5->pack_start($label, 0, 1, 0);
		$label->show;

		$adj = new Gtk::Adjustment $tree_default_depth, 0.0, 255.0, 1.0, 5.0, 0.0;

		$spinner = new Gtk::SpinButton $adj, 0, 0;
		$tree_depth_spinner = $spinner;
		$box5->pack_start($spinner, 0, 1, 0);
		$spinner->show;

		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 0, 0);
		$separator->show;

		$box2 = new Gtk::HBox 0, 0;
		$box2->border_width(5);
		$box1->pack_start($box2, 0, 0, 0);
		$box2->show;

		$button = new Gtk::Button 'Create Sample Tree';
		$button->signal_connect("clicked", \&cb_create_tree);
		$box2->pack_start($button, 1, 1, 0);
		$button->show;

		$button = new Gtk::Button 'Close';
		$button->signal_connect("clicked", sub {destroy $tree_mode_window});
		$box2->pack_start($button, 1, 1, 0);
		$button->show;

	}

	if (!$tree_mode_window->visible) {
		show $tree_mode_window;
	} else {
		destroy $tree_mode_window;
	}

}

sub create_handlebox {
	my ($toolbar, $hbox);

	if ( !defined $handlebox_window ) {
		$handlebox_window = new Gtk::Window "toplevel";
		$handlebox_window->signal_connect("destroy", \&destroy_window, \$handlebox_window);
		$handlebox_window->signal_connect("delete_event", \&destroy_window, \$handlebox_window);
		$handlebox_window->set_title("Handle Box Test");
		$handlebox_window->border_width(20);

		$hbox = new Gtk::HandleBox;
		$hbox->show;
		$handlebox_window->add($hbox);

		$toolbar = make_toolbar($handlebox_window);
		$toolbar->show;
		$hbox->add($toolbar);
	}

	if (!$handlebox_window->visible) {
		show $handlebox_window;
	} else {
		destroy $handlebox_window;
	}

}

my $statusbar_counter = 1;

sub statusbar_push {
	my( $widget, $statusbar ) = @_;

	$statusbar->push( 1, "Something " . ($statusbar_counter++) );
}

sub statusbar_pop {
	my( $widget, $statusbar ) = @_;

	$statusbar->pop( 1 );
}

sub statusbar_steal {
	my( $widget, $statusbar ) = @_;

	$statusbar->remove( 1, 4 );
}

sub statusbar_popped {
	my( $statusbar, $context_id, $text ) = @_;

	if ( ! $statusbar->messages ) {
		$statusbar_counter = 1;
	}
}

sub statusbar_contexts {
	my( $button, $statusbar ) = @_;

	my $string;
	
	foreach $string ( 'any context', 'idle messages', 'some text', 'hit the mouse', 'hit the mouse2' ) {
		print "Gtk::StatusBar: context = \"$string\", context_id=", $statusbar->get_context_id( $string ), "\n";
	}
}

sub statusbar_dump_stack {
	my( $button, $statusbar ) = @_;

	my $msg;

	foreach $msg ( $statusbar->messages ) {
		print "context_id: %{$msg}{context_id}, message_id: %{$msg}{message_id}, status_text: \"%{$msg}{text}\"\n";
	}
	
}

sub create_statusbar {
	my($box1, $box2, $button, $separator, $statusbar);
	
	if (not defined $statusbar_window) {
		$statusbar_window = new Gtk::Window -toplevel;
		
		$statusbar_window->signal_connect("destroy", \&Gtk::Widget::destroyed, \$statusbar_window);
		
		$statusbar_window->set_title("statusbar");
		border_width $statusbar_window 0;
		
		$box1 = new Gtk::VBox 0, 0;
		$statusbar_window->add($box1);
		show $box1;
		
		$box2 = new Gtk::VBox 0, 10;
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		show $box2;
		
		$statusbar = new Gtk::Statusbar;
		$box1->pack_end($statusbar, 1, 1, 0);
		show $statusbar;
		$statusbar->signal_connect("text_popped", \&statusbar_popped);
		
		$button = new Gtk::Widget "Gtk::Button",
			-label => "push something",
			-visible => 1,
			-parent => $box2,
			GtkObject::signal::clicked => [\&statusbar_push, $statusbar];

		$button = new Gtk::Widget "Gtk::Button",
			-label => "pop",
			-visible => 1,
			-parent => $box2,
			-signal::clicked => [\&statusbar_pop, $statusbar];

		$button = new Gtk::Widget "Gtk::Button",
			-label => "steal #4",
			-visible => 1,
			-parent => $box2,
			-signal::clicked => [\&statusbar_steal, $statusbar];

		$button = new Gtk::Widget "Gtk::Button",
			-label => "dump stack",
			-visible => 1,
			-parent => $box2,
			-signal::clicked => [\&statusbar_dump_stack, $statusbar];

		$button = new Gtk::Widget "Gtk::Button",
			-label => "test contexts",
			-visible => 1,
			-parent => $box2,
			-signal::clicked => [\&statusbar_contexts, $statusbar];
			
		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);
		show $separator;
		
		$box2 = new Gtk::VBox 0, 10;
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		show $box2;
		
		$button = new Gtk::Button "close";
		$button->signal_connect("clicked", sub {$statusbar_window->destroy} );
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;
		$button->show;
		
	}
	
	if (not $statusbar_window->visible) {
		show $statusbar_window;
	} else {
		destroy $statusbar_window;
	}
	
}



sub reparent_label {
	my($widget, $new_parent) = @_;
	my($label) = ($widget->get_user_data);
	$label->reparent($new_parent);
}

sub create_reparent {
	my($box1, $box2, $box3, $frame, $button, $label, $separator);
	
	if (not defined $reparent_window) {
		$reparent_window = new Gtk::Window "toplevel";
		$reparent_window->signal_connect("destroy", \&destroy_window, \$reparent_window);
		$reparent_window->signal_connect("delete_event", \&destroy_window, \$reparent_window);
		$reparent_window->set_title("buttons");
		$reparent_window->border_width(0);
		
		$box1 = new Gtk::VBox(0, 0);
		$reparent_window->add($box1);
		show $box1;
		
		$box2 = new Gtk::HBox(0, 5);
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		show $box2;
		
		$label = new Gtk::Label "Hello World";
		
		$frame = new Gtk::Frame "Frame 1";
		$box2->pack_start($frame, 1, 1, 0);
		show $frame;
		
		$box3 = new Gtk::VBox 0, 5;
		$box3->border_width(5);
		$frame->add($box3);
		show $box3;
		
		$button = new Gtk::Button( 'switch' );
		$button->signal_connect( clicked => \&reparent_label, $box3);
		$button->set_user_data($label);
		$box3->pack_start($button, 0, 1, 0);
		$button->show;
		
		$box3->pack_start($label, 0, 1, 0);
		show $label;
		
		$frame = new Gtk::Frame "Frame 2";
		$box2->pack_start($frame, 1, 1, 0);
		show $frame;
		
		$box3 = new Gtk::VBox 0, 5;
		$box3->border_width(5);
		$frame->add($box3);
		show $box3;
		
		$button = new Gtk::Button "switch";
		$button->signal_connect( clicked => \&reparent_label, $box3);
		$button->set_user_data($label);
		$box3->pack_start($button, 0, 1, 0);
		$button->show;
		
		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);
		$separator->show;
		
		$box2 = new Gtk::VBox (0, 10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;
		
		$button = new Gtk::Button "close";
		signal_connect $button clicked => sub {destroy $reparent_window};
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;
		$button->show;
    }

	if (!$reparent_window->visible) {
		show $reparent_window;
	} else {
		destroy $reparent_window;
	}
}

sub create_pixmap {
	my($box1,$box2,$box3,$button,$label,$separator,$pixmapwid,$pixmap,$mask,$style);
	
	if (not defined $pixmap_window) {
		$pixmap_window = new Gtk::Window "toplevel";
		signal_connect $pixmap_window "destroy", \&destroy_window, \$pixmap_window;
		signal_connect $pixmap_window "delete_event", \&destroy_window, \$pixmap_window;
		$pixmap_window->set_title("pixmap");
		$pixmap_window->border_width(0);
		$pixmap_window->realize;
		
		$box1 = new Gtk::VBox(0,0);
		$pixmap_window->add($box1);
		$box1->show;
		
		$box2 = new Gtk::VBox(0, 10);
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;
		
		$button = new Gtk::Button;
		$box2->pack_start($button, 0, 0, 0);
		$button->show;
		
		$style = $button->get_style;

		($pixmap,$mask) = Gtk::Gdk::Pixmap->create_from_xpm($pixmap_window->window, $style->bg('normal'), "xpm/test.xpm");
      	$pixmapwid = new Gtk::Pixmap $pixmap, $mask;
      	
      	$label = new Gtk::Label "Pixmap test\n";
      	$box3 = new Gtk::HBox(0,0);
      	$box3->border_width(2);
      	$box3->add($pixmapwid);
      	$box3->add($label);
      	$button->add($box3);
      	$pixmapwid->show;
      	$label->show;
      	$box3->show;
      	
      	$separator = new Gtk::HSeparator;
      	$box1->pack_start($separator, 0, 1, 0);
      	$separator->show;
      	
      	$box2 = new Gtk::VBox(0,10);
      	$box2->border_width(10);
      	$box1->pack_start($box2, 0, 1, 0);
      	$box2->show;
      	
      	$button = new Gtk::Button "close";
      	$button->signal_connect("clicked", sub { destroy $pixmap_window } );
      	$box2->pack_start($button, 1, 1, 0);
      	$button->can_default(1);
      	$button->grab_default;
      	$button->show;
	}
	if (!visible $pixmap_window) {
		show $pixmap_window;
	} else {
		destroy $pixmap_window;
	}
}

#use Data::Dumper;

sub tips_query_widget_entered {
	print "entered: ";
#	print Dumper(\@_);
	my($tips_query, $widget, $tip_text, $tip_private, $toggle) = @_;
	
	if ($toggle->active) {
		$tips_query->set(defined($tip_text) ? "There is a Tip!" : "There is no Tip!");
		# Don't let GtkTipsQuery reset it's label
		$tips_query->signal_emit_stop_by_name("widget_entered");
	}
}

sub tips_query_widget_selected {
	print "selected: ";
#	print Dumper(\@_);
	my($tips_query, $widget, $tip_text, $tip_private, $event, $func_data) = @_;
	if ($widget) {
		printf "Help \"%s\" requested for <%s>\n", defined($tip_private) ? $tip_private : "None", $widget->type_name;
	}
}

sub create_tooltips {
	my($box1,$box2,$box3, $button,$toggle,$frame,$tips_query,$separator,$tooltips);
	
	if (not defined $tt_window) {
#		print "1\n";
		$tt_window = new Gtk::Widget "Gtk::Window",
							type => -toplevel,
							border_width => 0,
							title => "Tooltips",
							allow_shrink => 1,
							allow_grow => 0,
							auto_shrink => 1,
							width => 200,
							signal::destroy => [\&destroy_tooltips, \$tt_window];

#		print "2\n";
		
		$tooltips = new Gtk::Tooltips;
		$tt_window->{tooltips} = $tooltips;
		
		$box1 = new Gtk::VBox(0, 0);
		$tt_window->add($box1);
		$box1->show;
		
		$box2 =  new Gtk::VBox(0,10);
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;
		
		$button = new Gtk::ToggleButton("button1");
		$box2->pack_start($button, 1, 1, 0);
		$button->show;
		
		$tooltips->set_tip($button, "This is button 1", "ContextHelp/buttons/1");
		
		$button = new Gtk::ToggleButton("button2");
		$box2->pack_start($button, 1, 1, 0);
		show $button;
		
		set_tip $tooltips $button => "This is button 2. This is also a really long tooltip which probably won't fit on a single line and will therefore need to be wrapped. Hopefully the wrapping will work correctly.", "ContextHelp/buttons/2_long";
		
		$toggle = new Gtk::ToggleButton "Override TipsQuery Label";
		$box2->pack_start($toggle, 1, 1, 0);
		$toggle->show;
		
		set_tip $tooltips $toggle => "Toggle TipsQuery view.", "Hi msw! ;)";
		
		$box3 = new Gtk::Widget "Gtk::VBox",
						homogeneous => 0,
						spacing => 5,
						border_width => 5,
						visible => 1;

		$tips_query = new Gtk::TipsQuery;
		
		$button = new Gtk::Widget "Gtk::Button",
						label => "[?]",
						visible => 1,
						parent => $box3,
						signal::clicked => sub {$tips_query->start_query};
		$box3->set_child_packing($button, 0, 0, 0, 'start');
		
		$tooltips->set_tip($button, "Start the Tooltips Inspector", "ContextHelp/buttons/?");
		
		Gtk::Object::set($tips_query,	'visible' => 1,
						'parent' => $box3,
						'caller' => $button,
						'widget_entered' => sub {tips_query_widget_entered @_, $toggle}, # [\&tips_query_widget_entered, $toggle],
						'widget_selected' => \&tips_query_widget_selected);
		
		$frame = new Gtk::Widget "Gtk::Frame",
						label => "ToolTips Inspector",
						label_xalign => 0.5,
						border_width => 0,
						visible => 1,
						parent => $box2,
						child => $box3;
		$box2->set_child_packing($frame, 1, 1, 10, 'start');
		
		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);
		show $separator;
		
		$box2 = new Gtk::VBox (0, 10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;
		
		$button = new Gtk::Button "close";
		$button->signal_connect("clicked", sub { destroy $tt_window});
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;
		$button->show;
		
		$tooltips->set_tip($button, "Push this button to close window", "ContextHelp/buttons/Close");
    }
	if (!visible $tt_window) {
		show $tt_window;
	} else {
		$tt_window->hide;
	}
}

sub create_scrolled_windows {
	my($scrolled_window,$table,$button,$buffer,$i,$j);
	
	if (not defined $s_window) {
		$s_window = new Gtk::Dialog;
		$s_window->signal_connect("destroy", \&destroy_window, \$s_window);
		$s_window->signal_connect("delete_event", \&destroy_window, \$s_window);
		$s_window->set_title("dialog");
		$s_window->border_width(0);
		
		$scrolled_window = new Gtk::ScrolledWindow(undef,undef);
		$scrolled_window->border_width(10);
		$scrolled_window->set_policy(-automatic, -automatic);
		$s_window->vbox->pack_start($scrolled_window, 1, 1, 0);
		$scrolled_window->show;
		
		$table = new Gtk::Table(20,20,0);
		$table->set_row_spacings(10);
		$table->set_col_spacings(10);
		$scrolled_window->add_with_viewport($table);
		$table->show;
		
		for ($i=0;$i<20;$i++)
		{
			for($j=0;$j<20;$j++)
			{
				$button = new Gtk::Button "button ($i,$j)\n";
				$table->attach_defaults($button, $i, $i+1, $j, $j+1);
				$button->show;
			}
		}
		
		$button = new Gtk::Button "close";
		$button->signal_connect("clicked", sub {destroy $s_window});
		$button->can_default(1);
		$s_window->action_area->pack_start($button, 1, 1, 0);
		$button->grab_default;
		$button->show;
	}
	if (!visible $s_window) {
		show $s_window;
	} else {
		destroy $s_window;
	}
}

sub create_entry {
	my($box1,$box2,$entry,$cb, $editable,$button,$separator);
	
	if (not defined $entry_window) {
		$entry_window = new Gtk::Window -toplevel;
		$entry_window->signal_connect("destroy", \&destroy_window, \$entry_window);
		$entry_window->signal_connect("delete_event", \&destroy_window, \$entry_window);
		$entry_window->set_title("entry");
		$entry_window->border_width(0);
		
		$box1 = new Gtk::VBox(0,0);
		$entry_window->add($box1);
		$box1->show;
		
		$box2 = new Gtk::VBox(0,10);
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;
		
		$entry = new Gtk::Entry;
		#$entry->set_usize(0, 25);
		$entry->set_text("hello world");
		$entry->select_region(0, length($entry->get_text));
		$box2->pack_start($entry, 1, 1, 0);
		$entry->show;

		$cb = new Gtk::Combo;
		$cb->set_popdown_strings('item1', 'item2', 'and item3');
		$cb->entry->set_text('hello world');
		$cb->entry->select_region(0, length($cb->entry->get_text));
		$cb->show;
		$box2->pack_start($cb, 1, 1, 0);

		$editable = new Gtk::CheckButton('Editable');
		$editable->signal_connect('toggled', sub {$entry->set_editable($_[0]->active)});
		$editable->set_active(1);
		$editable->show;
		$box2->pack_start($editable, 1, 1, 0);

		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);
		$separator->show;
		
		$box2 = new Gtk::VBox(0,10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;
		
		$button = new Gtk::Button "close";
		$button->signal_connect("clicked", sub {destroy $entry_window});
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;
		$button->show;
	}
	if (!visible $entry_window) {
		show $entry_window;
	} else {
		destroy $entry_window;
	}
}

sub list_add
{
	my($widget,$list) = @_;
	Gtk->print("list_add\n");
}

sub list_remove
{
	my($widget, $list) = @_;
	
	$list->remove_items($list->selection);
}

sub create_list
{
	my(@list_items) = 
	(
	    'hello',
	    'world',
	    'blah',
	    'foo',
	    'bar',
	    'argh',
	    'spencer',
	    'is a',
	    'wussy',
	    'programmer',
	);
	my($box1,$box2,$scrolled_win,$list,$list_item,$button,$separator,$i);
	
	if (not defined $list_window) {
		$list_window = new Gtk::Window -toplevel;
		$list_window->signal_connect("destroy", \&destroy_window, \$list_window);
		$list_window->signal_connect("delete_event", \&destroy_window, \$list_window);
		$list_window->set_title("list");
		$list_window->border_width(0);
		
		$box1 = new Gtk::VBox(0,0);
		$list_window->add($box1);
		$box1->show;
		
		$box2 = new Gtk::VBox(0, 10);
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;
		
		$scrolled_win = new Gtk::ScrolledWindow(undef, undef);
		$scrolled_win->set_policy(-automatic, -automatic);
		$box2->pack_start($scrolled_win, 1, 1, 0);
		$scrolled_win->show;
		
		$list = new Gtk::List;
		$list->set_selection_mode(-multiple);
		$list->set_selection_mode(-browse);
		$scrolled_win->add_with_viewport($list);
		$list->show;
		
		for($i=0;$i<@list_items;$i++)
		{
			$list_item = new Gtk::ListItem($list_items[$i]);
			$list->add($list_item);
			$list_item->show;
		}
		
		$button = new Gtk::Button "add";
		$button->can_focus(0);
		$button->signal_connect("clicked", \&list_add, $list);
		$box2->pack_start($button, 0, 1, 0);
		$button->show;
		
		$button = new Gtk::Button "remove";
		$button->can_focus(0);
		$button->signal_connect("clicked", \&list_remove, $list);
		$box2->pack_start($button, 0, 1, 0);
		$button->show;
		
		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);
		$separator->show;
		
		$box2 = new Gtk::VBox(0,10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;
		
		$button = new Gtk::Button "close";
		$button->signal_connect("clicked", sub { destroy $list_window});
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;
		$button->show;
	}
	if (not $list_window->visible) {
		show $list_window;
	} else {
		destroy $list_window;
	}
}

# clist

my $clist_selected_row = 0;
my $clist_rows = 0;

#use Data::Dumper;

sub select_clist {
	#print "Entering select_clist: ", Dumper(\@_);

	my($widget, $row, $column, $event) = @_;

	my($i);
 
    $widget->set_focus_row ($row);

	print "Gtk::CList Selection: row $row column $column button ", $event ? $event->{button} : 0, "\n";
  
	for($i=0;$i<$widget->columns;$i++) {
	  	my($type) = $widget->get_cell_type($row, $i);
	  	if ($type eq "text") {
	  		print "CELL $i GTK_CELL_TEXT\n";
	  		print "TEXT: ", $widget->get_text($row,$i), "\n";
	  	} elsif ($type eq "pixmap") {
	  		print "CELL $i GTK_CELL_PIXMAP\n";
	  		my($pixmap, $mask) = $widget->get_pixmap($row,$i);
	  		print "PIXMAP: $pixmap\n";
	  		print "MASK: $mask\n";
	  	} elsif ($type eq "pixtext") {
	  		print "CELL $i GTK_CELL_PIXTEXT\n";
	  		my($text,$spacing,$pixmap, $mask) = $widget->get_pixtext($row,$i);
	  		print "TEXT: $text\n";
	  		print "SPACING: $spacing\n";
	  		print "PIXMAP: $pixmap\n";
	  		print "MASK: $mask\n";
	  	}
	}
  
	print "\nSelected rows:";
	foreach ($widget->selection) {
		print " $_ ";
	}
	print "\n";

	$clist_selected_row=$row;
}

sub unselect_clist {
	#print "Entering unselect_clist: ", Dumper(\@_);

	my( $widget, $row, $column, $event ) = @_;

	my( $i );
  
	print "Gtk::CList Unselection: row $row column $column button ", $event ? $event->{button} : 0, "\n";
  
	for($i=0;$i<$widget->columns;$i++) {
  		my($type) = $widget->get_cell_type($row, $i);
  		if ($type eq "text") {
  			print "CELL $i GTK_CELL_TEXT\n";
  			print "TEXT: ", $widget->get_text($row,$i), "\n";
  		} elsif ($type eq "pixmap") {
  			print "CELL $i GTK_CELL_PIXMAP\n";
  			my($pixmap, $mask) = $widget->get_pixmap($row,$i);
  			print "PIXMAP: $pixmap\n";
  			print "MASK: $mask\n";
  		} elsif ($type eq "pixtext") {
  			print "CELL $i GTK_CELL_PIXTEXT\n";
  			my($text,$spacing,$pixmap, $mask) = $widget->get_pixtext($row,$i);
  			print "TEXT: $text\n";
  			print "SPACING: $spacing\n";
  			print "PIXMAP: $pixmap\n";
  			print "MASK: $mask\n";
  		}
	}
  
	print "\nSelected rows:";
	foreach ($widget->selection) {
	  	print " $_ ";
	}
	print "\n";

	$clist_selected_row=$row;
}

sub add1000_clist {
	my($widget, $clist)= @_;
  
	my($pixmap, $mask) = Gtk::Gdk::Pixmap->create_from_xpm($clist->clist_window, $clist->style->white, "xpm/test.xpm");
	my $row_nr = 0;
	my @text = ( 'Right', 'Center', 'Column 3', 'Column 4', 'Column 5', 'Column 6' );
	my $i;

	$clist->freeze();

	for $i ( 1 .. 1000 ) {
		$row_nr = $clist_rows + $i;
		$clist->append( "Row $row_nr", @text);
		$clist->set_pixtext($row_nr, 3, "Testing", 5, $pixmap, $mask);
	}
	$clist->thaw();
	$clist_rows += 1000;
}

sub add10000_clist {
	my($widget, $clist)= @_;

	my $row_nr = 0;
	my $i;

	$clist->freeze();
	for $i ( 1 .. 10000 ) {
		$row_nr = $clist_rows + $i;
		$clist->append( ( "Row $row_nr" , 'Right', 'Center', 'Column 3', 'Column 4', 'Column 5', 'Column 6' ) );
	}
	$clist->thaw();
	$clist_rows += 1000;
}

sub create_clist {
	my (@titles, @text, $clist, $box1, $box2, $button, $separator);

	@titles = (
	    "Title 0",
	    "Title 1",
	    "Title 2",
	    "Title 3",
	    "Title 4",
	    "Title 5",
	    "Title 6"
	);

	my $i;

	if (not defined $clist_window) {
		$clist_window = new Gtk::Window -toplevel;
		$clist_window->signal_connect("destroy", \&destroy_window, \$clist_window);
		$clist_window->signal_connect("delete_event", \&destroy_window, \$clist_window);
		$clist_window->set_title("clist");
		$clist_window->border_width(0);
		
		$box1 = new Gtk::VBox(0,0);
		$clist_window->add($box1);
		$box1->show;
		
		$box2 = new Gtk::HBox(0, 10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 0, 0);
		$box2->show;

		my $scrolled_win = new Gtk::ScrolledWindow(undef, undef);
		$scrolled_win->set_policy('automatic', 'automatic');

		$clist = new_with_titles Gtk::CList(@titles);
#		$clist = new Gtk::CList($#titles + 1);
		
		$button = new Gtk::Button('Add 1,000 Rows with pixmaps');
		$button->show;
		$button->signal_connect('clicked', \&add1000_clist, $clist);
		$box2->pack_start($button, 1, 1, 0);

		$button = new Gtk::Button('Add 10,000 Rows');
		$button->show;
		$button->signal_connect('clicked', \&add10000_clist, $clist);
		$box2->pack_start($button, 1, 1, 0);

		$button = new Gtk::Button('Clear list');
		$button->show;
		$button->signal_connect('clicked', sub {$clist->clear; $clist_rows = 0;});
		$box2->pack_start($button, 1, 1, 0);

		$button = new Gtk::Button('Remove Row');
		$button->show;
		$button->signal_connect('clicked', sub {$clist->remove($clist_selected_row); $clist_rows--;});
		$box2->pack_start($button, 1, 1, 0);

		$box2 = new Gtk::HBox(0, 10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 0, 0);
		$box2->show;

		$button = new Gtk::Button('Insert Row');
		$button->show;
		$button->signal_connect('clicked', sub {$clist->insert( $clist_selected_row, ( 'This', 'is', 'a', 'inserted', 'row', 'la la la la la', 'la la la la' ) ); $clist_rows++;});
		$box2->pack_start($button, 1, 1, 0);

		$button = new Gtk::Button('Show Title Buttons');
		$button->show;
		$button->signal_connect('clicked', sub {$clist->column_titles_show();});
		$box2->pack_start($button, 1, 1, 0);

		$button = new Gtk::Button('Hide Title Buttons');
		$button->show;
		$button->signal_connect('clicked', sub {$clist->column_titles_hide();});
		$box2->pack_start($button, 1, 1, 0);

		$box2 = new Gtk::VBox(0, 10);
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;

		$clist->set_row_height(20);

		$clist->signal_connect('select_row', \&select_clist);
		$clist->signal_connect('unselect_row', \&unselect_clist);

		$clist->set_sort_column(0);
		$clist->set_compare_func(sub {
			shift; 
			return $_[0] cmp $_[1]
		});
		$clist->set_column_width(0, 100);

		for $i ( 1 .. scalar(@titles) ) {
			$clist->set_column_width($i, 80);
			$text[$i] = "Column $i";
		}
		$clist->set_selection_mode('browse');
		$clist->set_column_justification(1, 'right');
		$clist->set_column_justification(2, 'center');
#		$clist->column_titles_show();

		$text[1] = 'Right';
		$text[2] = 'Center';
		shift(@text);

		for $i ( 0 .. 100 ) {
			$clist->append( "Row $i", @text);
		}

		$clist_rows=100;
		$clist_selected_row=0;

		$clist->border_width(5);
		$scrolled_win->add($clist);
		$box2->pack_start($scrolled_win, 1, 1, 0);
		$clist->show;
		$scrolled_win->show;

		$separator = new Gtk::HSeparator;
		$separator->show;
		$box1->pack_start($separator, 0, 1, 0);

		$box2 = new Gtk::VBox(0, 10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;

		$button = new Gtk::Button('sort');
		$button->signal_connect('clicked', sub {$clist->sort});
		$box2->pack_start($button, 1, 1, 0);
		$button->show;

		$button = new Gtk::Button('close');
		$button->signal_connect('clicked', sub {$clist_window->destroy});
		$button->can_default(1);
		$button->grab_default;
		$box2->pack_start($button, 1, 1, 0);
		$button->show;
	}
	if (not $clist_window->visible) {
		show $clist_window;
	} else {
		destroy $clist_window;
	}
}

# ctree demo global variables;

my $books = 0;
my $pages = 0;

my $sel_label;
my $vis_label;
my $book_label;
my $page_label;

my $spin1;
my $spin2;
my $spin3;

sub ctree_expand_all {
	my ( $widget, $ctree ) = @_;

	$ctree->expand_recursive( undef );
	ctree_after_press( $ctree, undef );
}

sub ctree_collapse_all {
	my ( $widget, $ctree ) = @_;

	$ctree->collapse_recursive( undef );
	ctree_after_press( $ctree, undef );
}

sub ctree_select_all {
	my ( $widget, $ctree ) = @_;

	$ctree->select_recursive( undef );
	ctree_after_press( $ctree, undef );
}

sub ctree_unselect_all {
	my ( $widget, $ctree ) = @_;

	$ctree->unselect_recursive( undef );
	ctree_after_press( $ctree, undef );
}

sub ctree_count_items {
	my ( $ctree, $node ) = @_;

	if ( $node->row->is_leaf() ) {
		$pages--;
	} else {
		$books--;
	}
}

sub ctree_remove_selection {
	my ( $widget, $ctree ) = @_;

	$ctree->freeze();

	my @selection = $ctree->selection();
	my $new_sel = undef;
	my $node;

	for $node ( @selection ) {

		my $row = $node->row();

# TRYME
		if ( $node->row->is_leaf() ) {
			$pages--;
		} else {
			$ctree->post_recursive( $node, \&ctree_count_items, undef );
		}

		if ( $ctree->selection_mode() eq 'browse' ) {

			my $children = $row->children();

			if ( defined $children ) {
				$new_sel = $row->sibling();
				if ( not defined $new_sel ) {
					$new_sel = $node->next();
				}
			} else {
				$new_sel = $node->next();
				if ( not defined $new_sel ) {
					$new_sel = $node->prev();
				}
			}
		}

		$ctree->remove_node( $node );

# FIXME:
#		@selection = $ctree->selection();
	}

	if ( $new_sel ) {
		$ctree->select( $new_sel );
	}

	$ctree->thaw();

	ctree_after_press( $ctree, undef );
}

sub ctree_sort {
	my ( $widget, $ctree ) = @_;

	$ctree->sort_recursive( undef );
}

sub ctree_export {
	my ( $widget, $ctree ) = @_;

# FIXME
#	if ( not defined $export_window ) {
#		
#	}
}

sub ctree_button_press {
	my( $ctree, $event, $data ) = @_;

	my ( $row, $column ) = $ctree->get_selection_info( $event->{'x'}, $event->{'y'} );

	if ( not defined $row and $event->{button} != 3 ) {
		return 0;
	}

	if ( $event->{button} == 1 ) {
		if ( $ctree->selection_mode() eq 'multiple' and $event->{state} & 1 ) {
			$ctree->signal_emit_stop_by_name( 'button_press-event' );
		}
	} elsif ( $event->{button} == 2 ) {
		my @rows = $ctree->row_list;
		my $work = $rows[$row];
		my $children = $work->children;
		if ( defined $children && $ctree->is_hot_spot( $event->{'x'}, $event->{'y'} ) ) {
			if ( $work->expanded() ) {
				$ctree->collapse_recursive( $work->children );
			} else {
				$ctree->expand_recursive( $work->children );
			}
			ctree_after_press( $ctree, undef );
			$ctree->signal_emit_stop_by_name( 'button_press_event' );
		}
	}

	return 0;
}

sub ctree_after_press {
	my ( $ctree, $data ) = @_;

	my @selection = $ctree->selection();
	$sel_label->set( $#selection + 1 );

	my @row_list = $ctree->row_list();
	$vis_label->set( $#row_list + 1 );

	$book_label->set( $books );

	$page_label->set( $pages );

	return 0;
}

sub ctree_button_release {
	my ( $ctree, $event, $data ) = @_;

	my ( $row, $column ) = $ctree->get_selection_info( $event->{'x'}, $event->{'y'} );

	if ( not defined $row or $event->{button} != 1 ) {
		return 0;
	}

	my @row_list = $ctree->row_list;
	my $work = $row_list[$row];

# FIXME
#	if ( $ctree->selection_mode eq 'multiple' and $event->{state} & 1 ) {
#		if ( $work->row->state == 'selected' ) {
#			$clist->unselect_recursive( $work );
#		} else {
#			$clist->select_recursive( $work );
#		}
#		ctree_after_press( $ctree, undef );
#		$ctree->signal_emit_stop_by_name( 'button_release_event' );
#	}

	return 0;

}

sub ctree_change_row_height {
	my ( $widget, $ctree ) = @_;

	$ctree->set_row_height( $widget->value );
}

sub ctree_change_indent {
	my ( $widget, $ctree ) = @_;

	$ctree->set_indent( $widget->value );
}

sub ctree_toggle_reorderable {
	my ( $widget, $ctree ) = @_;

	$ctree->set_reorderable( $widget->active );
}

sub ctree_toggle_line_style {
	my ( $widget, $ctree ) = @_;

	if ( not $widget->mapped() ) {
		return;
	}

	my @styles = ( 'none', 'tabbed', 'dotted', 'solid' );
	my ( $line_style, $i );

	$i = find_radio_menu_toggled( $widget );

# FIXME
#	$line_style = $ctree->line_style;
#	if (
#		( $line_style eq 'tabbed' and $styles[$i] ne 'tabbed' ) or
#		( $line_style ne 'tabbed' and $styles[$i] eq 'tabbed' )
#	) {
#		$ctree->prerecursive( undef, \&ctree_set_background, undef );
#	}

	$ctree->set_line_style( $styles[$i] );
}

sub ctree_toggle_justify {
	my ( $widget, $ctree ) = @_;

	if ( not $widget->mapped() ) {
		return;
	}

	my @justification = ( 'right', 'left' );
	my $i;

	$i = find_radio_menu_toggled( $widget );
	$ctree->set_column_justification( $ctree->tree_column(), $justification[$i] );
}

sub ctree_toggle_sel_mode {
	my ( $widget, $ctree ) = @_;

	if ( not $widget->mapped() ) {
		return;
	}

	my @modes = ( 'extended', 'multiple', 'browse', 'single' );
	my $i;

	$i = find_radio_menu_toggled( $widget );
	$ctree->set_selection_mode( $modes[$i] );
}

sub ctree_build_recursive {
	my (
		$ctree,
		$cur_depth,
		$depth,
		$num_books,
		$num_pages,
		$parent
	) = @_;

	my ( $i, $text );
	my $sibling = undef;

	for ( $i = $num_pages + $num_books; $i > $num_books; $i-- ) {

		$pages ++;
		my $random = int ( rand ( 100 ) );
		my $text = [ "Page $random", "Item $cur_depth-$i" ];

		$sibling = $ctree->insert_node (
			$parent,
			$sibling,
			$text,
			5,
			$mini_page,
			$mini_page_mask,
			undef,
			undef,
			1,
			0
		);

# FIXME
		if ( $ctree->line_style() eq 'tabbed' ) {
#			$ctree->set_background( $sibling, $col_bg );
		}

	}

	if ( $cur_depth == $depth ) {
		return;
	}

	for ( $i = $num_books; $i > 0; $i-- ) {

		$books++;
		my $random = int ( rand ( 100 ) );
		$text = [ "Book $random", "Item $cur_depth-$i" ];

		$sibling = $ctree->insert_node (
			$parent,
			$sibling,
			$text,
			5,
			$book_closed,
			$book_closed_mask,
			$book_open,
			$book_open_mask,
			0,
			0
		);

# FIXME
#		if ( $cur_depth % 3 == 0 ) {
#			col_bg->{red} = 10000 * ( $cur_depth % 6 );
#			col_bg->{green} = 0;
#			col_bg->{blue} = 65535 - ( ( $i * 10000 ) % 65535 );
#		} elsif ( $cur_depth % 3 == 1 ) {
#			col_bg->{red} = 10000 * ( $cur_depth % 6 );
#			col_bg->{green} = 65535 - ( ( $i * 10000 ) % 65535 );
#			col_bg->{blue} = 0;
#		} else {
#			col_bg->{red} = 65535 - ( ( $i * 10000 ) % 65535 );
#			col_bg->{green} = 0;
#			col_bg->{blue} = 10000 * ( $cur_depth % 6 );
#		}
#		$ctree->get_colormap->color_alloc( $col_bg );
#		$ctree->node_set_row_data_full( $sibling, $coll_bg, g_free );

		ctree_build_recursive( $ctree, $cur_depth + 1, $depth, $num_books, $num_pages, $sibling );

	}

}

sub ctree_rebuild {
	my( $widget, $ctree ) = @_;

	my $parent;

	my $text = [ 'Root', '' ];

	my $d = $spin1->get_value_as_int;
	my $b = $spin2->get_value_as_int;
	my $p = $spin3->get_value_as_int;

	my $i = ( ( ( $b ** $d ) - 1 ) / ( $b - 1 ) ) * ( $p + 1 );
	if ( $i > 100000 ) {
		print "$i total items? Try less\n";
		return;
	}

	$ctree->freeze;
	$ctree->clear;

	$books = 1;
	$pages = 0;

	$parent = $ctree->insert_node(
		undef,
		undef,
		$text,
		5,
		$book_closed,
		$book_closed_mask,
		$book_open,
		$book_open_mask,
		0,
		1
	);

# FIXME
#	$col_bg = g_new ( GdkColor, 1 );
#	$col_bg->red( 0 );
#	$col_bg->green( 45000 );
#	$col_gb->blue( 55000 );
#	$ctree->get_colormap->color_alloc( $col_bg );
#	$ctree->node_set_data_full( $parent, $col_bg, g_free );
#	if ( $ctree->line_style == 'tabbed' ) {
#		$ctree->node_set_background( $parent, $col_bg );
#	}

	ctree_build_recursive( $ctree, 1, $d, $b, $p, $parent );

	$ctree->thaw;

	ctree_after_press( $ctree, undef );

}

sub ctree_click_column {
	my ( $ctree, $column, $data ) = @_;

	if ( $column == $ctree->sort_column() ) {
		if ( $ctree->sort_type() eq 'ascending' ) {
			$ctree->set_sort_type( 'descending' );
		} else {
			$ctree->set_sort_type( 'ascending' );
		}
	} else {
		$ctree->set_sort_column( $column );
	}
	$ctree->sort_recursive( undef );
}

sub ctree_after_move {
	my ($ctree, $child, $parent, $sibling) = @_;
	my ($source) = $ctree->get_node_info($child);
	my ($target1) = $ctree->get_node_info($parent) if $parent;
	my ($target2) = $ctree->get_node_info($sibling) if $sibling;

	$target1 ||= 'nil';
	$target2 ||= 'nil';
	
	print "Moving \"$source\" to \"$target1\" with sibling \"$target2\"\n";
}

sub create_ctree {

	if (not defined $ctree_window ) {

		my $items1 = [ 'Solid', 'Dotted', 'Tabbed', 'No lines' ];
		my $items2 = [ 'Left', 'Right' ];
		my $items3 = [ 'Single', 'Browse', 'Multiple', 'Extended' ];
		my @titles = ( 'Tree', 'Info' );

		my( $vbox, $hbox, $label, $adj, $button, $ctree, $spinner, $hbox2, $check, $omenu1, $omenu2, $omenu3, $frame, $transparent );

		$ctree_window = new Gtk::Window( 'toplevel' );
		$ctree_window->signal_connect( 'destroy' , \&destroy_window, \$ctree_window );
		$ctree_window->signal_connect( 'delete_event', \&destroy_window, \$ctree_window );
		$ctree_window->set_title( 'GtkCtree' );
		$ctree_window->border_width( 0 );

		$vbox = new Gtk::VBox( 0, 0 );
		$ctree_window->add( $vbox );

		$hbox = new Gtk::HBox( 0, 5 );
		$hbox->border_width( 5 );
		$vbox->pack_start( $hbox, 0, 1, 0 );

		$label = new Gtk::Label( 'Depth :' );
		$hbox->pack_start( $label, 0, 1, 0 );

		$adj = new Gtk::Adjustment( 4, 1, 10, 1, 5, 0 );
		$spin1 = new Gtk::SpinButton( $adj, 0, 0 );
		$hbox->pack_start( $spin1, 0, 1, 5 );

		$label = new Gtk::Label( 'Books :' );
		$hbox->pack_start( $label, 0, 1, 0 );

		$adj = new Gtk::Adjustment( 3, 1, 20, 1, 5, 0 );
		$spin2 = new Gtk::SpinButton( $adj, 0, 0 );
		$hbox->pack_start( $spin2, 0, 1, 5 );

		$label = new Gtk::Label( 'Pages :' );
		$hbox->pack_start( $label, 0, 1, 0 );

		$adj = new Gtk::Adjustment( 5, 1, 20, 1, 5, 0 );
		$spin3 = new Gtk::SpinButton( $adj, 0, 0 );
		$hbox->pack_start( $spin3, 0, 1, 5 );

		$button = new Gtk::Button( 'Close' );
		$hbox->pack_end( $button, 1, 1, 0 );

		$button->signal_connect( 'clicked', sub { $ctree_window->destroy } );

		$button = new Gtk::Button( 'Rebuild tree' );
		$hbox->pack_start( $button, 1, 1, 0 );

		my $scrolled_win = new Gtk::ScrolledWindow(undef,undef);
		$scrolled_win->set_policy( 'always', 'automatic' );

		$ctree = new_with_titles Gtk::CTree ( 0, @titles );
		$ctree->set_line_style( 'dotted' );
		$ctree->drag_source_set('button3_mask', ['copy', 'move'], {target=>'STRING', flags=>0, info=>0});
		$ctree->signal_connect('drag_data_get', sub {
			my ($w, $context, $data, $info, $time) = @_;
			$data->set($data->target, 8, $w->{"my-drag-info"});
		});
		$ctree->signal_connect('drag_begin', sub {
			my ($w, $context) = @_;
			my ($x,$y) = $w->clist_window->get_pointer();
			my ($row) = $w->get_selection_info($x, $y);
			my ($node) = $w->node_nth($row);
			print "Got row: $row\n";
			($w->{"my-drag-info"}) = $w->get_node_info($node);
		});
		$ctree->set_reorderable( 1 );

		$ctree->signal_connect( 'click_column', \&ctree_click_column );
		$ctree->signal_connect( 'button_press_event', \&ctree_button_press );
		$ctree->signal_connect_after( 'button_press_event', \&ctree_after_press );
		$ctree->signal_connect( 'button_release_event', \&ctree_button_release );
		$ctree->signal_connect( 'tree_select_row', sub {
			my ($ct, $node, $col) = @_;
			my ($t, $space);
			# print "Column: $col -> $node\n";
			($t, undef, undef) = $ct->node_get_pixtext($node, 0);
			print "Info 0: $t\n";
			$t = $ct->node_get_text($node, 1);
			print "Info 1: $t\n";
			($t, $space) = $ct->get_node_info($node);
			print "NInfo: '$t' $space\n";
		} );
		$ctree->signal_connect_after( 'button_release_event', \&ctree_after_press );
		$ctree->signal_connect_after( 'tree_move', \&ctree_after_move );
		$ctree->signal_connect_after( 'end_selection', \&ctree_after_press );
		$ctree->signal_connect_after( 'toggle_focus_row', \&ctree_after_press );
		$ctree->signal_connect_after( 'select_all', \&ctree_after_press );
		$ctree->signal_connect_after( 'unselect_all', \&ctree_after_press );
		$ctree->signal_connect_after( 'scroll_vertical', \&ctree_after_press );

		$scrolled_win->add($ctree);
		$vbox->pack_start( $scrolled_win, 1, 1, 0 );

		$ctree->set_selection_mode( 'extended' );
		$ctree->set_column_width( 0, 200 );
		$ctree->set_column_width( 1, 200 );

		$button->signal_connect( 'clicked', \&ctree_rebuild, $ctree );

		$hbox = new Gtk::HBox( 0, 5 );
		$hbox->border_width( 5 );
		$vbox->pack_start( $hbox, 0, 1, 0 );

		$button = new Gtk::Button( 'Expand all' );
		$button->signal_connect( 'clicked', \&ctree_expand_all, $ctree );
		$hbox->pack_start( $button, 1, 1, 0 );

		$button = new Gtk::Button( 'Collapse all' );
		$button->signal_connect( 'clicked', \&ctree_collapse_all, $ctree );
		$hbox->pack_start( $button, 1, 1, 0 );

		$button = new Gtk::Button( 'Sort tree' );
		$button->signal_connect( 'clicked', \&ctree_sort, $ctree );
		$hbox->pack_start( $button, 1, 1, 0 );

		$button = new Gtk::Button( 'Export tree' );
		$button->signal_connect( 'clicked', \&ctree_export, $ctree );
		$hbox->pack_start( $button, 1, 1, 0 );

		$hbox = new Gtk::HBox( 0, 5 );
		$hbox->border_width( 5 );
		$vbox->pack_start( $hbox, 0, 1, 0 );

		$label = new Gtk::Label( 'Row height :' );
		$hbox->pack_start( $label, 0, 1, 0 );

		$adj = new Gtk::Adjustment( 20, 12, 100, 1, 10, 0 );
		$spinner = new Gtk::SpinButton( $adj, 0, 0 );
# FIXME: gtk_tooltips_set_tip
		$adj->signal_connect( 'value_changed', \&ctree_change_row_height, $ctree );
		$hbox->pack_start( $spinner, 0, 1, 5 );

		$ctree->set_row_height( $adj->value );

		$button = new Gtk::Button( 'Select all' );
		$button->signal_connect( 'clicked', \&ctree_select_all, $ctree );
		$hbox->pack_start( $button, 1, 1, 0 );

		$button = new Gtk::Button( 'Unselect all' );
		$button->signal_connect( 'clicked', \&ctree_unselect_all, $ctree );
		$hbox->pack_start( $button, 1, 1, 0 );

		$button = new Gtk::Button( 'Remove selection' );
		$button->signal_connect( 'clicked', \&ctree_remove_selection, $ctree );
		$hbox->pack_start( $button, 1, 1, 0 );

		$hbox = new Gtk::HBox( 1, 5 );
		$hbox->border_width( 5 );
		$vbox->pack_start( $hbox, 0, 1, 0 );

		$hbox2 = new Gtk::HBox( 0, 0 );
		$hbox->pack_start( $hbox2, 0, 1, 0 );

		$label = new Gtk::Label( 'Indent :' );
		$hbox2->pack_start( $label, 0, 1, 0 );

		$adj = new Gtk::Adjustment( 20, 0, 60, 1, 10, 0 );
		$spinner = new Gtk::SpinButton( $adj, 0, 0 );
# FIXME: gtk_tooltips_set_tip
		$adj->signal_connect( 'value_changed', \&ctree_change_indent, $ctree );
		$hbox2->pack_start( $spinner, 0, 1, 5 );

		$check = new Gtk::CheckButton( 'Reorderable' );
# FIXME: gtk_tooltips_set_tip
		$check->signal_connect( 'clicked', \&ctree_toggle_reorderable, $ctree );
		$hbox->pack_start( $check, 0, 1, 0 );
		$check->set_active( 1 );

		$omenu1 = build_option_menu( $items1, \&ctree_toggle_line_style, 4, 1, $ctree );
# FIXME: gtk_tooltips_set_tip
		$hbox->pack_start( $omenu1, 0, 1, 0 );

		$omenu2 = build_option_menu( $items2, \&ctree_toggle_justify, 2, 0, $ctree );
# FIXME: gtk_tooltips_set_tip
		$hbox->pack_start( $omenu2, 0, 1, 0 );

		$omenu3 = build_option_menu( $items3, \&ctree_toggle_sel_mode, 4, 3, $ctree );
# FIXME: gtk_tooltips_set_tip
		$hbox->pack_start( $omenu3, 0, 1, 0 );

		$ctree_window->realize;

		($book_open, $book_open_mask) = create_from_xpm_d Gtk::Gdk::Pixmap( $ctree_window->window, undef, @book_open_xpm );
		($book_closed, $book_closed_mask) = create_from_xpm_d Gtk::Gdk::Pixmap( $ctree_window->window, undef, @book_closed_xpm );
		($mini_page, $mini_page_mask ) = create_from_xpm_d Gtk::Gdk::Pixmap( $ctree_window->window, undef, @mini_page_xpm );

		$ctree->set_usize( 0, 300 );

		$frame = new Gtk::Frame( undef );
		$frame->border_width( 0 );
		$frame->set_shadow_type ( 'out' );
		$vbox->pack_start( $frame, 0, 1, 0 );

		$hbox = new Gtk::HBox( 1, 2 );
		$hbox->border_width( 2 );
		$frame->add( $hbox );

		$frame = new Gtk::Frame( undef );
		$frame->set_shadow_type ( 'in' );
		$hbox->pack_start( $frame, 0, 1, 0 );

		$hbox2 = new Gtk::HBox( 0, 0 );
		$hbox2->border_width( 2 );
		$frame->add( $hbox2);

		$label = new Gtk::Label( 'Books :' );
		$hbox2->pack_start( $label, 0, 1, 0 );

		$book_label = new Gtk::Label ( "$books" );
		$hbox2->pack_end( $book_label, 0, 1, 5 );

		$frame = new Gtk::Frame( undef );
		$frame->set_shadow_type ( 'in' );
		$hbox->pack_start( $frame, 0, 1, 0 );

		$hbox2 = new Gtk::HBox( 0, 0 );
		$hbox2->border_width( 2 );
		$frame->add( $hbox2);

		$label = new Gtk::Label( 'Pages :' );
		$hbox2->pack_start( $label, 0, 1, 0 );

		$page_label = new Gtk::Label ( "$pages" );
		$hbox2->pack_end( $page_label, 0, 1, 5 );

		$frame = new Gtk::Frame( undef );
		$frame->set_shadow_type ( 'in' );
		$hbox->pack_start( $frame, 0, 1, 0 );

		$hbox2 = new Gtk::HBox( 0, 0 );
		$hbox2->border_width( 2 );
		$frame->add( $hbox2);

		$label = new Gtk::Label( 'Selected :' );
		$hbox2->pack_start( $label, 0, 1, 0 );

		my @selected = $ctree->selection();

		$sel_label = new Gtk::Label ( $#selected );
		$hbox2->pack_end( $sel_label, 0, 1, 5 );

		$frame = new Gtk::Frame( undef );
		$frame->set_shadow_type ( 'in' );
		$hbox->pack_start( $frame, 0, 1, 0 );

		$hbox2 = new Gtk::HBox( 0, 0 );
		$hbox2->border_width( 2 );
		$frame->add( $hbox2);

		$label = new Gtk::Label( 'Visible :' );
		$hbox2->pack_start( $label, 0, 1, 0 );

		my @row_list = $ctree->row_list();

		$vis_label = new Gtk::Label ( $#row_list );
		$hbox2->pack_end( $vis_label, 0, 1, 5 );

		ctree_rebuild( undef, $ctree );

	}
	if (not $ctree_window->visible) {
		$ctree_window->show_all;
	} else {
		$ctree_window->destroy;
	}

}

sub create_menu {
	my($depth) = @_;
	my($menu,$submenu,$menuitem);
	
	if ($depth<1) {
		return undef;
	}
	
	$menu = new Gtk::Menu;
	$submenu = undef;
	$menuitem = undef;
	
	my($i,$j);
	for($i=0,$j=1;$i<5;$i++,$j++)
	{
		my($buffer) = sprintf("item %2d - %d", $depth, $j);
		$menuitem = new Gtk::RadioMenuItem($buffer, $menuitem);
		$menu->append($menuitem);
		$menuitem->set_show_toggle(1) if $depth % 2;
		$menuitem->show;
		if ($depth>1) {
			if (not defined $submenu) {
				$submenu = create_menu($depth-1);
				$menuitem->set_submenu($submenu);
			}
		}
	}
	
	return $menu;
}

sub create_menus {
	my($box1,$box2,$button,$menu,$menubar,$menuitem,$optionmenu,$separator);
	
	if (not defined $menu_window) {
		$menu_window = new Gtk::Window -toplevel;
		signal_connect $menu_window destroy => \&destroy_window, \$menu_window;
		signal_connect $menu_window delete_event => \&destroy_window, \$menu_window;
		$menu_window->set_title("menus");
		$menu_window->border_width(0);
		
		$box1 = new Gtk::VBox(0,0);
		$menu_window->add($box1);
		$box1->show;
		
		$menubar = new Gtk::MenuBar;
		$box1->pack_start($menubar, 0, 1, 0);
		$menubar->show;
		
		$menu = create_menu(2);
		
		$menuitem = new Gtk::MenuItem("test");
		$menuitem->set_submenu($menu);
		$menubar->append($menuitem);
		show $menuitem;

		$menu = create_menu(3);
		
		$menuitem = new Gtk::MenuItem("foo");
		$menuitem->set_submenu($menu);
		$menubar->append($menuitem);
		show $menuitem;

		$menu = create_menu(4);
		
		$menuitem = new Gtk::MenuItem("bar");
		$menuitem->set_submenu($menu);
		$menubar->append($menuitem);
		show $menuitem;

		$box2 = new Gtk::VBox(0,10);
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;
		
		$optionmenu = new Gtk::OptionMenu;
		$optionmenu->set_menu(create_menu(1));
		$optionmenu->set_history(4);
		$box2->pack_start($optionmenu, 1, 1, 0);
		$optionmenu->show;
		
		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);
		show $separator;
		
		$box2 = new Gtk::VBox(0,10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;
		
		$button = new Gtk::Button "close";
		signal_connect $button clicked => sub { destroy $menu_window};
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;
		$button->show;
	}
	if (!visible $menu_window) {
		show $menu_window;
	} else {	
		destroy $menu_window;
	}
}

sub item_factory_cb {
	my ($widget, $action, @data) = @_;

	print "ItemFactory: activated ", $widget->item_factory_path(), " -> ", $action, "\n";
}

my @item_factory_entries = (
	["/_File",	undef,	0,	"<Branch>"],
	["/File/tearoff1",	undef,	0,	"<Tearoff>"],
	["/File/_New",	"<control>N",	1],
	["/File/_Open",	"<control>O",	2],
	["/File/_Save", "<control>S",	3],
	["/File/Save _As...",	undef,	4],
	["/File/sep1",	undef,	0,	"<Separator>"],
	#["/File/_Quit",	"<control>Q",	5],
	{
		'path' => "/File/_Quit", 
		'accelerator' => "<control>Q",	
		'action' => 5,
		'type' => '<Item>'
	},
	
	["/_Preferences",	undef,	0,	"<Branch>"],
	["/_Preferences/_Color",	undef,	0,	"<Branch>"],
	["/_Preferences/Color/_Red",	undef,	10,	"<RadioItem>"],
	["/_Preferences/Color/_Green",	undef,	11,	"<RadioItem>"],
	["/_Preferences/Color/_Blue",	undef,	12,	"<RadioItem>"],
	["/_Preferences/_Shape",	undef,	0,	"<Branch>"],
	["/_Preferences/Shape/_Square",	undef,	20,	"<RadioItem>"],
	["/_Preferences/Shape/_Rectangle",	undef,	21,	"<RadioItem>"],
	["/_Preferences/Shape/_Oval",	undef,	22,	"<RadioItem>"],

	["/_Help",	undef,	0,	"<LastBranch>"],
	["/Help/_About",	undef,	30]
);

sub create_item_factory {
	if (!defined $item_factory_window) {
		my ($accel_group, $item_factory, $box1, $label, $box2);
		my ($separator, $button, $dummy);

		
		$item_factory_window = new Gtk::Window('toplevel');
		signal_connect $item_factory_window destroy => \&destroy_window, \$item_factory_window;
		signal_connect $item_factory_window "delete-event" => \&destroy_window, \$item_factory_window;

		$accel_group = new Gtk::AccelGroup;
		$item_factory = new Gtk::ItemFactory('Gtk::MenuBar', "<main>", $accel_group);
		
		#$item_factory_window->set_data('<main>', $item_factory);
		$accel_group->attach($item_factory_window);
		# $item_factory->create_items();
		foreach (@item_factory_entries) {
			$item_factory->create_item($_, \&item_factory_cb);
		}
		
		$item_factory_window->set_title("Item Factory");
		$item_factory_window->set_border_width(0);
		
		$box1 = new Gtk::VBox(0, 0);
		$item_factory_window->add($box1);
		$box1->pack_start($item_factory->get_widget('<main>'), 0, 0, 0);

		$label = new Gtk::Label "Type\n<alt>\nto start";

		$label->set_usize(200, 200);
		$label->set_alignment(0.5, 0.5);
		$box1->pack_start($label, 1, 1, 0);

		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);

		$box2 = new Gtk::VBox(0, 10);
		$box2->set_border_width(10);
		$box1->pack_start($box2, 0, 1, 0);

		$button = new Gtk::Button("close");
		$button->signal_connect('clicked', sub {$item_factory_window->destroy;});
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;

	}
	if (!visible $item_factory_window) {
		show_all $item_factory_window;
	} else {
		destroy $item_factory_window;
	}
}

sub color_selection_ok {
	my($widget, $dialog) = @_;
	
	my(@color) = $dialog->colorsel->get_color;
	print "color=@color\n";
	$dialog->colorsel->set_color(@color);
}

sub color_selection_changed {
	my($widget, $dialog) = @_;

	my(@color) = $dialog->colorsel->get_color;
	print "color=@color\n";
}

sub create_color_selection {
	if (not defined $cs_window) {
		set_install_cmap Gtk::Preview 1;
		Gtk::Widget->push_visual(Gtk::Preview->get_visual);
		Gtk::Widget->push_colormap(Gtk::Preview->get_cmap);
		
		$cs_window = new Gtk::ColorSelectionDialog "color selection dialog";
		
		$cs_window->colorsel->set_opacity(1);
		$cs_window->colorsel->set_update_policy(-continuous);
		$cs_window->position(-mouse);
		signal_connect $cs_window destroy => \&destroy_window, \$cs_window;
		$cs_window->colorsel->signal_connect("color_changed", \&color_selection_changed, $cs_window);
		$cs_window->ok_button->signal_connect("clicked", \&color_selection_ok, $cs_window);
		$cs_window->cancel_button->signal_connect("clicked", sub { destroy $cs_window });
		
		pop_colormap Gtk::Widget;
		pop_visual Gtk::Widget;
	}
	if (!visible $cs_window) {
		show $cs_window;
	} else {
		destroy $cs_window;
	}
}

sub file_selection_ok {
	my($widget, $fs) = @_;
	Gtk->print( $fs->get_filename . "\n");
	
}

sub create_file_selection {
	if (not defined $fs_window) {
		$fs_window = new Gtk::FileSelection "file selection dialog";
		$fs_window->position(-mouse);
		$fs_window->signal_connect("destroy", \&destroy_window, \$fs_window);
		$fs_window->signal_connect("delete_event", \&destroy_window, \$fs_window);
		$fs_window->ok_button->signal_connect("clicked", \&file_selection_ok, $fs_window);
		$fs_window->cancel_button->signal_connect("clicked", sub { destroy $fs_window });
		
	}
	if (!visible $fs_window) {
		show $fs_window;
	} else {
		destroy $fs_window;
	}
}

sub font_selection_ok {
	my($widget, $font) = @_;
	Gtk->print( $font->get_font_name . "\n");
}

sub create_font_selection {
	if (not defined $font_window) {
		$font_window = new Gtk::FontSelectionDialog "Font Selection Dialog";
		$font_window->position(-mouse);
		$font_window->signal_connect("destroy", \&destroy_window, \$font_window);
		$font_window->signal_connect("delete_event", \&destroy_window, \$font_window);
		$font_window->ok_button->signal_connect("clicked", \&font_selection_ok, $font_window);
		$font_window->cancel_button->signal_connect("clicked", sub { destroy $font_window });
		
	}
	if (!visible $font_window) {
		show $font_window;
	} else {
		destroy $font_window;
	}
}

sub create_range_controls {
	my($box1,$box2,$button,$scrollbar,$scale,$separator,$adjustment);
	
	if (not defined $range_window) {
		$range_window = new Gtk::Window -toplevel;
		$range_window->signal_connect("destroy", \&destroy_window, \$range_window);
		$range_window->signal_connect("delete_event", \&destroy_window, \$range_window);
		$range_window->set_title("range controls");
		$range_window->border_width(0);
		
		$box1 = new Gtk::VBox(0,0);
		$range_window->add($box1);
		$box1->show;
		
		$box2 = new Gtk::VBox(0,10);
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;
		
		$adjustment = new Gtk::Adjustment(0.0, 0.0, 101.0, 0.1, 1.0, 1.0);
		
		$scale = new Gtk::HScale($adjustment);
		$scale->set_usize(150,30);
		$scale->set_update_policy(-delayed);
		$scale->set_digits(1);
		$scale->set_draw_value(1);
		$box2->pack_start($scale, 1, 1, 0);
		$scale->show;
		
		$scrollbar = new Gtk::HScrollbar $adjustment;
		$scrollbar->set_update_policy(-continuous);
		$box2->pack_start($scrollbar, 1, 1, 0);
		$scrollbar->show;
		
		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 0);
		$separator->show;
		
		$box2 = new Gtk::VBox(0,10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;
		
		$button = new Gtk::Button "close";
		$button->signal_connect("clicked", sub {destroy $range_window});
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;
		show $button;
	}
	if (!visible $range_window) {
		show $range_window;
	} else {
		destroy $range_window;
	}
}

sub create_rulers {
	my($table);
	
	if (not defined $ruler_window) {
		$ruler_window = new Gtk::Window 'toplevel';
		$ruler_window->signal_connect("destroy", \&destroy_window, \$ruler_window);
		$ruler_window->signal_connect("delete_event", \&destroy_window, \$ruler_window);
		$ruler_window->set_title("rulers");
		$ruler_window->set_usize(300, 300);
		$ruler_window->set_events(["pointer_motion_mask", "pointer_motion_hint_mask"]);
		$ruler_window->border_width(0);
		
		$table = new Gtk::Table(2,2,0);
		$ruler_window->add($table);
		show $table;
		
		{
		my($ruler) = new Gtk::HRuler;
		$ruler->set_range(5, 15, 0, 20);
		$ruler_window->signal_connect("motion_notify_event", 
			sub { my($widget,$event)=@_; $ruler->motion_notify_event($event) });
		$table->attach($ruler, 1, 2, 0, 1, [-expand, -fill], [-fill], 0, 0);
		$ruler->show;
		}

		{
		my($ruler) = new Gtk::VRuler;
		$ruler->set_range(5, 15, 0, 20);
		$ruler_window->signal_connect("motion_notify_event", 
			sub { my($widget,$event)=@_; $ruler->motion_notify_event($event) });
		$table->attach($ruler, 0, 1, 1, 2, [-fill], [-expand, -fill], 0, 0);
		$ruler->show;
		}
		
	}
	if (!visible $ruler_window) {
		show $ruler_window;
	} else {
		destroy $ruler_window;
	}
}

sub create_text {
	my($box1,$box2,$button,$separator,$table,$hscrollbar,$vscrollbar,$text);
	
	if (not defined $text_window) {
		$text_window = new Gtk::Window "toplevel";
		$text_window->set_name("text window");
		$text_window->signal_connect("destroy", \&destroy_window, \$text_window);
		$text_window->signal_connect("delete_event", \&destroy_window, \$text_window);
		$text_window->set_title("test");
		$text_window->border_width(0);
		
		$box1 = new Gtk::VBox(0,0);
		$text_window->add($box1);
		$box1->show;
		
		$box2 = new Gtk::VBox(0,10);
		$box2->border_width(10);
		$box1->pack_start($box2,1,1,0);
		$box2->show;
		
		$table = new Gtk::Table(2,2,0);
		$table->set_row_spacing(0,2);
		$table->set_col_spacing(0,2);
		$box2->pack_start($table,1,1,0);
		$table->show;
		
		$text = new Gtk::Text(undef,undef);
		#$table->attach_defaults($text, 0,1,0,1);
		$table->attach($text, 0,1,0,1,  0, 0,0,0);
		show $text;
		
		$hscrollbar = new Gtk::HScrollbar($text->hadj);
		$table->attach($hscrollbar, 0, 1,1,2,[-expand,-fill],[-fill],0,0);
		$hscrollbar->show;

		$vscrollbar = new Gtk::VScrollbar($text->vadj);
		$table->attach($vscrollbar, 1, 2,0,1,[-fill],[-expand,-fill],0,0);
		$vscrollbar->show;
		
		$text->freeze;
		$text->realize;
		
		$text->insert(undef,$text->style->white,undef, "spencer blah blah blah blah blah blah blah blah blah\n");
		$text->insert(undef,$text->style->white,undef, "kimball\n");
		$text->insert(undef,$text->style->white,undef, "is\n");
		$text->insert(undef,$text->style->white,undef, "a\n");
		$text->insert(undef,$text->style->white,undef, "wuss.\n");
		$text->insert(undef,$text->style->white,undef, "but\n");
		$text->insert(undef,$text->style->white,undef, "josephine\n");
		$text->insert(undef,$text->style->white,undef, "(his\n");
		$text->insert(undef,$text->style->white,undef, "girlfriend\n");
		$text->insert(undef,$text->style->white,undef, "is\n");
		$text->insert(undef,$text->style->white,undef, "not).\n");
		$text->insert(undef,$text->style->white,undef, "why?\n");
		$text->insert(undef,$text->style->white,undef, "because\n");
		$text->insert(undef,$text->style->white,undef, "spencer\n");
		$text->insert(undef,$text->style->white,undef, "puked\n");
		$text->insert(undef,$text->style->white,undef, "last\n");
		$text->insert(undef,$text->style->white,undef, "night\n");
		$text->insert(undef,$text->style->white,undef, "but\n");
		$text->insert(undef,$text->style->white,undef, "josephine\n");
		$text->insert(undef,$text->style->white,undef, "did\n");
		$text->insert(undef,$text->style->white,undef, "not");
		$text->insert(undef,$text->style->white,undef, "whereas\n");
		$text->insert(undef,$text->style->white,undef, "kenneth\n");
		$text->insert(undef,$text->style->white,undef, "is\n");
		$text->insert(undef,$text->style->white,undef, "undoubtedly\n");
		$text->insert(undef,$text->style->white,undef, "more\n");
		$text->insert(undef,$text->style->white,undef, "wussful\n");
		$text->insert(undef,$text->style->white,undef, "by default\nn");
		$text->insert(undef,$text->style->white,undef, "not\n");
		$text->insert(undef,$text->style->white,undef, "having\n");
		$text->insert(undef,$text->style->white,undef, "any\n");
		$text->insert(undef,$text->style->white,undef, "more\n");
		$text->insert(undef,$text->style->white,undef, "information\n");
		$text->insert(undef,$text->style->white,undef, "to\n");
		$text->insert(undef,$text->style->white,undef, "base\n");
		$text->insert(undef,$text->style->white,undef, "a\n");
		$text->insert(undef,$text->style->white,undef, "comparison on\n");

		
		$text->thaw;

		$separator = new Gtk::HSeparator();
		$box1->pack_start($separator,0,1,0);
		$separator->show;
		
		$box2 = new Gtk::VBox(0,10);
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		$box2->show;
		
		$button = new Gtk::Button "close";
		$button->signal_connect("clicked", sub {destroy $text_window});
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;
		$button->show;
		
	}
	if (!visible $text_window) {
		show $text_window;
	} else {
		destroy $text_window;
	}
}

# notebook demo global variables

my $notebook_window;

sub notebook_page_switch {
	my( $widget, $new_page, $page_num) = @_;

	print "switch page $page_num\n";

	my $old_page = $widget->cur_page();
	if ( defined $old_page ) {
		if ($new_page == $old_page) {
			return;
		}
	}

	my $new_page_tab_pixmap = ($new_page->tab_label->children)[0]->widget;
	my $new_page_menu_pixmap = ($new_page->menu_label->children)[0]->widget;

	$new_page_tab_pixmap->set( $book_open, $book_open_mask );
	$new_page_menu_pixmap->set( $book_open, $book_open_mask );
	
	if ( defined $old_page ) {
		my $old_page_tab_pixmap = ($old_page->tab_label->children)[0]->widget;
		my $old_page_menu_pixmap = ($old_page->menu_label->children)[0]->widget;

		$old_page_tab_pixmap->set( $book_closed, $book_closed_mask  );
		$old_page_menu_pixmap->set( $book_closed, $book_closed_mask );
	}
	
}

sub notebook_create_pages {
	my( $notebook, $start, $end ) = @_;
	
	my(
		$child,
		$label,
		$entry,
		$box,
		$hbox,
		$label_box,
		$menu_box,
		$button,
		$pixwid,
		$i,
		$buffer
	);
	
	for $i ( $start .. $end ) {

		$buffer = "Page $i";
		
		if ( ( $i % 4 ) == 3 ) {
			$child = new Gtk::Button( $buffer );
			$child->border_width( 10 );
		} elsif ( ( $i % 4 ) == 2 ) {
			$child = new Gtk::Label( $buffer );
		} elsif ( ( $i % 4 ) == 1 ) {
			$child = new Gtk::Frame( $buffer );
			$child->border_width( 10 );
			$box = new Gtk::VBox( 1, 0 );
			$box->border_width( 10 );
			$child->add( $box );

			$label = new Gtk::Label $buffer;
			$box->pack_start($label, 1, 1, 5);

			$entry = new Gtk::Entry;
			$box->pack_start($entry, 1, 1, 5);

			$hbox = new Gtk::HBox 1, 0;
			$box->pack_start($hbox, 1, 1, 5);

			$button = new Gtk::Button "Ok";
			$hbox->pack_start($button, 1, 1, 5);

			$button = new Gtk::Button "Cancel";
			$hbox->pack_start($button, 1, 1, 5);
		} else {
			$child = new Gtk::Frame( $buffer );
			$child->border_width( 10 );
			$label = new Gtk::Label( $buffer );
			$child->add( $label );
		}
		
		$child->show_all();
		
		$label_box = new Gtk::HBox 0, 0;
		$pixwid = new Gtk::Pixmap $book_closed, $book_closed_mask;
		$label_box->pack_start($pixwid, 0, 1, 0);
		$pixwid->set_padding(3, 1);
		$label = new Gtk::Label $buffer;
		$label_box->pack_start($label, 0, 1, 0);
		show_all $label_box;
		
		$menu_box = new Gtk::HBox( 0, 0 );
		$pixwid = new Gtk::Pixmap( $book_closed, $book_closed_mask );
		$menu_box ->pack_start( $pixwid, 0, 1, 0 );
		$pixwid->set_padding( 3, 1);
		$label = new Gtk::Label( $buffer) ;
		$menu_box->pack_start( $label, 0, 1, 0 );
		$menu_box->show_all();
		
		$notebook->append_page_menu($child, $label_box, $menu_box);
	}
}

sub notebook_rotate {
	my( $button, $notebook ) = @_;

	my %rotate = (
		top => "right",
		right => "bottom",
		bottom => "left",
		left => "top"
	);

	$notebook->set_tab_pos( $rotate{ $notebook->tab_pos } );
}

sub notebook_standard {
	my( $button, $notebook ) = @_;
	
	$notebook->set_show_tabs( 1 );
	$notebook->set_scrollable( 0 );
	if ( $notebook->children == 15 ) {
		my $i;
		for $i (0 .. 9 ) {
			$notebook->remove_page( 5 );
		}
	}
}

sub notebook_notabs {
	my( $button, $notebook ) = @_;

	$notebook->set_show_tabs( 0 );
	if ( $notebook->children == 15 ) {
		my $i;
		for $i ( 0 .. 9 ) {
			$notebook->remove_page( 5 );
		}
	}
}

sub notebook_scrollable {
	my( $button, $notebook ) = @_;

	$notebook->set_show_tabs( 1 );
	$notebook->set_scrollable( 1 );
	if ( $notebook->children == 5 ) {
		notebook_create_pages( $notebook, 6, 15 );
	}
}

sub notebook_popup {
	my( $button, $notebook ) = @_;

	if ( $button->active ) {
		$notebook->popup_enable;
	} else {
		$notebook->popup_disable;
	}
}

sub create_notebook {
	my(
		$box1,
		$box2,
		$button,
		$separator,
		$notebook,
		$omenu,
		$menu,
		$submenu,
		$menuitem,
		$group,
		$transparent
	);
	
	if (not defined $notebook_window) {

		$notebook_window = new Gtk::Window( 'toplevel' );
		
		$notebook_window->signal_connect( 'destroy', \&Gtk::Widget::destroyed, \$notebook_window );
		$notebook_window->set_title("notebook");
		$notebook_window->border_width(0);
		
		$box1 = new Gtk::VBox 0, 0;
		$notebook_window->add($box1);
		
		$notebook = new Gtk::Notebook;
		$notebook->signal_connect( 'switch_page', \&notebook_page_switch );
		$notebook->set_tab_pos(-top);
		$box1->pack_start($notebook, 1, 1, 0);
		$notebook->border_width(10);
		
		$notebook->realize;
		($book_open, $book_open_mask) = Gtk::Gdk::Pixmap->create_from_xpm_d($notebook->window, $transparent, @book_open_xpm);
		($book_closed, $book_closed_mask) = Gtk::Gdk::Pixmap->create_from_xpm_d($notebook->window, $transparent, @book_closed_xpm);
		
		notebook_create_pages($notebook, 1, 5);
		
		$separator = new Gtk::HSeparator();
		$box1->pack_start( $separator, 0, 1, 10 );
		
		$box2 = new Gtk::HBox( 1, 5 );
		$box1->pack_start( $box2, 0, 1, 0 );
		
		$omenu = new Gtk::OptionMenu();
		$menu = new Gtk::Menu();
		$submenu = undef;
		$menuitem = undef;
		
		$menuitem = new Gtk::RadioMenuItem "Standard", $menuitem;
		$menuitem->signal_connect("activate", \&notebook_standard, $notebook);
		$menu->append($menuitem);
		$menuitem->show;

		$menuitem = new Gtk::RadioMenuItem "w/o Tabs", $menuitem;
		$menuitem->signal_connect("activate", \&notebook_notabs, $notebook);
		$menu->append($menuitem);
		$menuitem->show;

		$menuitem = new Gtk::RadioMenuItem "Scrollable", $menuitem;
		$menuitem->signal_connect("activate", \&notebook_scrollable, $notebook);
		$menu->append($menuitem);
		$menuitem->show;
		
		$omenu->set_menu($menu);
		$box2->pack_start($omenu, 0, 0, 0);
		$button = new Gtk::CheckButton "Enable popup menu";
		$box2->pack_start($button, 0, 0, 0);
		$button->signal_connect("clicked", \&notebook_popup, $notebook);
		
		$box2 = new Gtk::HBox 0, 10;
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		
		$button = new Gtk::Button( 'Close' );
		$button->signal_connect( 'clicked', sub { $notebook_window->destroy } );
		$box2->pack_start( $button, 1, 1, 0 );
		$button->can_default( 1 );
		$button->grab_default;
		
		$button = new Gtk::Button( 'Next' );
		$button->signal_connect( 'clicked', sub { $notebook->next_page } );
		$box2->pack_start( $button, 1, 1, 0 );
		
		$button = new Gtk::Button( 'Prev' );
		$button->signal_connect( 'clicked', sub { $notebook->prev_page } );
		$box2->pack_start( $button, 1, 1, 0 );

		$button = new Gtk::Button( 'Rotate' );
		$button->signal_connect( 'clicked', \&notebook_rotate, $notebook );
		$box2->pack_start( $button, 1, 1, 0 );
	}
	
	if (! $notebook_window->visible) {
		$notebook_window->show_all();
	} else {
		$notebook_window->destroy();
	}
}

# paned demo

sub create_panes {
	my($frame,$hpaned,$vpaned);
	if (not defined $paned_window) {
		$paned_window = new Gtk::Window "toplevel";
		$paned_window->signal_connect("destroy", \&destroy_window, \$paned_window);
		$paned_window->signal_connect("delete_event", \&destroy_window, \$paned_window);
		$paned_window->set_title("Panes");
		$paned_window->border_width(0);
		
		$vpaned = new Gtk::VPaned;
		$paned_window->add($vpaned);
		$vpaned->border_width(5);
		$vpaned->show;

		$hpaned = new Gtk::HPaned;
		$vpaned->add1($hpaned);

		$frame = new Gtk::Frame;
		$frame->set_shadow_type("in");
		$frame->set_usize(60,60);
		$hpaned->add1($frame);
		$frame->show;

		$frame = new Gtk::Frame;
		$frame->set_shadow_type("in");
		$frame->set_usize(80,60);
		$hpaned->add2($frame);
		$frame->show;
		
		$hpaned->show;
		
		$frame = new Gtk::Frame;
		$frame->set_shadow_type("in");
		$frame->set_usize(60,80);
		$vpaned->add2($frame);
		$frame->show;

	}
	if (not visible $paned_window) {
		show $paned_window;
	} else {
		destroy $paned_window;
	}
}

# progressbar global variables

my $progress_timer;

sub progress_timeout_1_0 {
	my($progressbar) = @_;
	my($new_val) = $progressbar->percentage;
	$new_val += 0.02;
	if ($new_val>=1.0) {
		$new_val = 0.0;
	}
	
	$progressbar->update($new_val);
	
	return 1;
}

sub progress_timeout_1_1 {
	my($progressbar) = @_;
	my($new_val) = $progressbar->get_current_percentage;
	$new_val += 0.02;
	if ($new_val>=1.0) {
		$new_val = 0.0;
	}
	
	$progressbar->update($new_val);
	
	return 1;
}

sub destroy_progress {
	my($widget, $windowref) = @_;
	destroy_window($widget,$windowref);
	Gtk->timeout_remove($progress_timer);
	$progress_timer = 0;
	1;
}

sub create_progress_bar {
	my($button,$vbox,$pbar,$label);
	
	if (not defined $p_window) {
		$p_window = new Gtk::Dialog;
		signal_connect $p_window "destroy" => \&destroy_progress, \$p_window;
		signal_connect $p_window "delete_event" => \&destroy_progress, \$p_window;
		$p_window->set_title("dialog");
		$p_window->border_width(0);
		
		$vbox = new Gtk::VBox(0,5);
		$vbox->border_width(10);
		$p_window->vbox->pack_start($vbox,1,1,0);
		$vbox->show;
		
		$label = new Gtk::Label "progress...";
		$label->set_alignment(0.0,0.5);
		$vbox->pack_start($label,0,1,0);
		$label->show;
		
		$pbar = new Gtk::ProgressBar;
		$pbar->set_usize(200,20);
		$vbox->pack_start($pbar,1,1,0);
		$pbar->show;
		
		$progress_timer = Gtk->timeout_add(100, $gtk_1_0 ? \&progress_timeout_1_0 : \&progress_timeout_1_1, $pbar);
		
		$button = new Gtk::Button "close";
		$button->signal_connect("clicked", sub { destroy $p_window});
		$button->can_default(1);
		$p_window->action_area->pack_start($button,1,1,0);
		$button->grab_default;
		$button->show;
	}
	if (!$p_window->visible) {
		$p_window->show;
	} else {
		destroy $p_window;
	}
}

my($color_idle)=0;
my($color_count)=1;

sub color_idle_func {
	my($preview) = @_;
	my($i,$j,$k,$buf);
	$buf = "\0" x 32;
	for($i=0;$i<32;$i++)
	{
		for($j=0,$k=0;$j<32;$j++)
		{
			vec($buf, $k+0, 8) = $i+$color_count;
			vec($buf, $k+1, 8) = 0;
			vec($buf, $k+2, 8) = $j+$color_count;
			$k += 3;
		}
		$preview->draw_row($buf,0,$i,32);
	}
	
	$color_count +=1;
	
	$preview->draw(undef);
	
	return 1;
}


sub color_preview_destroy {
	my($widget,$windowref) = @_;
	if ($color_idle) {
		Gtk->idle_remove($color_idle);
	}
	$color_idle=0;
	
	destroy_window($widget, $windowref);
}

sub create_color_preview {
	my($preview,$buf,$i,$j,$k);
	
	if (not defined $cp_window) {
		Gtk::Widget->push_visual(Gtk::Preview->get_visual);
		Gtk::Widget->push_colormap(Gtk::Preview->get_cmap);
		
		$cp_window = new Gtk::Window "toplevel";
		$cp_window->signal_connect("destroy", \&color_preview_destroy, \$cp_window);
		$cp_window->signal_connect("delete_event", \&color_preview_destroy, \$cp_window);
		$cp_window->set_title("test");
		$cp_window->border_width(10);
		
		$preview = new Gtk::Preview("color");
		$preview->size(32,32);
		$cp_window->add($preview);
		$preview->show;
		
		for($i=0;$i<32;$i++)
		{
			for($j=0,$k=0;$j<32;$j++)
			{
				vec($buf,$k+0,8) = $i;
				vec($buf,$k+1,8) = 0;
				vec($buf,$k+2,8) = $j;
				$k+=3;
			}
			$preview->draw_row($buf, 0, $i, 32);
		}
		
		$color_idle = Gtk->idle_add(\&color_idle_func, $preview);
		
		Gtk::Widget->pop_colormap;
		Gtk::Widget->pop_visual;
		
	}
	if (!visible $cp_window) {
		show $cp_window;
	} else {
		destroy $cp_window;
	}
}

my($gray_idle)=0;
my($gray_count)=1;

sub gray_idle_func {
	my($preview) = @_;
	my($i,$j,$k,$buf);
	$buf = "\0" x 64;
	for($i=0;$i<64;$i++)
	{
		for($j=0;$j<64;$j++)
		{
			vec($buf, $j, 8) = $i + $j + $gray_count;
		}
		$preview->draw_row($buf,0,$i,64);
	}
	
	$gray_count +=1;
	
	$preview->draw(undef);
	
	return 1;
}

sub gray_preview_destroy {
	my($widget,$windowref) = @_;
	if ($gray_idle) {
		Gtk->idle_remove($gray_idle);
	}
	$gray_idle=0;
	
	destroy_window($widget, $windowref);
}

sub create_gray_preview {
	my($preview,$buf,$i,$j,$k);
	
	if (not defined $gp_window) {
		Gtk::Widget->push_visual(Gtk::Preview->get_visual);
		Gtk::Widget->push_colormap(Gtk::Preview->get_cmap);
		
		$gp_window = new Gtk::Window "toplevel";
		$gp_window->signal_connect("destroy", \&gray_preview_destroy, \$gp_window);
		$gp_window->signal_connect("delete_event", \&gray_preview_destroy, \$gp_window);
		$gp_window->set_title("test");
		$gp_window->border_width(10);
		
		$preview = new Gtk::Preview("grayscale");
		$preview->size(64,64);
		$gp_window->add($preview);
		$preview->show;
		
		for($i=0;$i<64;$i++)
		{
			for($j=0;$j<64;$j++)
			{
				vec($buf,$j,8) = $i+$j;
			}
			$preview->draw_row($buf, 0, $i, 64);
		}
		
		$gray_idle = Gtk->idle_add(\&gray_idle_func, $preview);
		
		Gtk::Widget->pop_colormap;
		Gtk::Widget->pop_visual;
		
	}
	if (!visible $gp_window) {
		show $gp_window;
	} else {
		destroy $gp_window;
	}
}

my($curve_count)=0;

sub create_gamma_curve {
	my( $gamma_curve, @vec, $i, $max );

	if (not defined $curve_window) {
		$curve_window = new Gtk::Window "toplevel";
		$curve_window->set_title("test");
		$curve_window->border_width(10);
		
		$gamma_curve = new Gtk::GammaCurve;
		$curve_window->add($gamma_curve);
		$gamma_curve->show;
	}

	$max = 127 + ($curve_count % 2) * 128;
	$gamma_curve->curve->set_range(0, $max, 0, $max);
	
	for($i=0;$i<$max;$i++) {
		$vec[$i] = (127 / sqrt($max))*sqrt($i);
	}
	$gamma_curve->curve->set_vector(@vec);
	
	if (!visible $curve_window) {
		show $curve_window;
	} elsif ($curve_count % 4 == 3) {
		destroy $curve_window;
		$curve_window = undef;
	}
	
	$curve_count++;
}

# scroll test global variables

my $scroll_test_pos = 0;
my $scroll_test_gc = undef;

sub scroll_test_expose {
	my($widget, $adj, $event) = @_;
	my($i,$j,$imin,$jmin,$imax,$jmax);
	
	$imin = $event->{area}->[0] / 10;
	$imax = ($event->{area}->[0] + $event->{area}->[2] + 9) / 10;

	$jmin = ($adj->get_value + $event->{area}->[1]) / 10;
	$jmax = ($adj->get_value + $event->{area}->[1] + $event->{area}->[3] + 9) / 10;
	
	$widget->window->clear_area($event->{area}->[0], $event->{area}->[1], 
								$event->{area}->[2], $event->{area}->[3]);
	
	for ($i=$imin; $i<$imax; $i++) {
		for ($j=$jmin; $j<$jmax; $j++) {
			if (($i+$j) % 2) {
				$widget->window->draw_rectangle($widget->style->black_gc, 1, 10*$i, 10*$j - $adj->get_value, 1+$i%10, 1+$j%10);
			}
		}
	}
	
	return 1;
}

sub scroll_test_configure {
	my($widget, $adj, $event) = @_;
	$adj->page_increment($widget->allocation->[3] * 0.9);
	$adj->page_size($widget->allocation->[3]);
	$adj->signal_emit("changed");
}

#FIXME
sub scroll_test_adjustment_changed {
	my($adj, $widget) = @_;
	
	my($source_min) = $adj->value - $scroll_test_pos;
	my($source_max) = $source_min + $widget->allocation->[3];
	my($dest_min) = 0;
	my($dest_max) = $widget->allocation->[3];
	my($r);
	
	$scroll_test_pos = $adj->value;
	
	return if not $widget->drawable;
	
	if ($source_min < 0) {
		$r = [0, 0, $widget->allocation->[2],-$source_min];
		if ($r->[3] > $widget->allocation->[3]) {
			$r->[3] = $widget->allocation->[3];
		}
		
		$source_min = 0;
		$dest_min = $r->[3];
	} else {
		$r = [0, 2*$widget->allocation->[3]-$source_max, $widget->allocation->[2], 0];
		if ($r->[1] < 0) {
			$r->[1] = 0;
		}
		$r->[3] = $widget->allocation->[3] - $r->[1];
		
		$source_max = $widget->allocation->[3];
		$dest_max = $r->[1];
	}
	
	if ($source_min != $source_max) {
		if (not defined $scroll_test_gc) {
			$scroll_test_gc = new Gtk::Gdk::GC $widget->window;
			$scroll_test_gc->set_exposures(1);
		}
		
		$widget->window->draw_pixmap($scroll_test_gc, $widget->window, 0, $source_min, 0, $dest_min, $widget->allocation->[2], $source_max - $source_min);
		
		my($event);
		
		while (defined ($event = $widget->window->event_get_graphics_expose)) {
			$widget->event($event);
			print "event = $event, type = $event->{type}\n";
			if ($event->{count} == 0) {
				last;
			}
		}
		
	}
	
	if ($r->[3] != 0) {
		$widget->draw($r);
	}
}


sub create_scroll_test {
    if (not defined $scroll_window) {
		$scroll_window = new Gtk::Dialog;
		$scroll_window->signal_connect ("destroy", \&destroy_window, \$dialog_window);

		$scroll_window->set_title ("Scroll Test");
		$scroll_window->border_width (0);
		
		my $hbox = new Gtk::HBox (0, 0);
		$hbox->border_width (10);
		$scroll_window->vbox->pack_start ($hbox, 1, 1, 0);
		$hbox->show;
		
		my $drawing_area = new Gtk::DrawingArea;
		$drawing_area->size(200, 200);
		$hbox->pack_start($drawing_area, 1, 1, 0);
		show $drawing_area;
		
		$drawing_area->set_events('exposure_mask');
		
		my $adj = new Gtk::Adjustment (0.0, 0.0, 1000.0, 1.0, 180.0, 200.0);
		$scroll_test_pos = 0.0;
		
		my $scrollbar = new Gtk::VScrollbar $adj;
		$hbox->pack_start($scrollbar, 0, 0, 0);
		show $scrollbar;
		
		$drawing_area->signal_connect(expose_event => \&scroll_test_expose, $adj);
		$drawing_area->signal_connect(configure_event => \&scroll_test_configure, $adj);

		$adj->signal_connect(value_changed => \&scroll_test_adjustment_changed, $drawing_area);
		
		my $button = new Gtk::Button "Quit";
		$scroll_window->action_area->pack_start($button, 1, 1, 0);
		
		$button->signal_connect(clicked => sub {destroy $scroll_window});
		show $button;
    }
	
    if (!$scroll_window->visible) {
		$scroll_window->show;
    } else {
		$scroll_window->destroy;
    }
}

sub selection_test_received
{
    my ($list, $selection_data) = @_;

	my $data = $selection_data->data;
	
    if (!defined $data) {
		warn ("Selection retrieval failed\n");
		return;
    }
    if ($selection_data->type != $Gtk::Atoms{ATOM}) {
		warn ("Selection TARGETS was not returned as atoms!\n");
		return;
    }
	
    # Clear out any current list items

    $list->clear_items (0, -1);
	
    # Add new items to list
    my @atoms = unpack("L*", $data);
    my @item_list = ();
	
    foreach (@atoms) {
		my $name = Gtk::Gdk::Atom->name($_);
		
		my $list_item = new Gtk::ListItem (defined $name ? $name : "(bad atom)");
		$list_item->show;
		
		push @item_list, $list_item;
    }

    $list->append_items (@item_list);
}

sub create_selection_test {
    if (not defined $sel_window) {
		$sel_window = new Gtk::Dialog;
		$sel_window->signal_connect ("destroy", \&destroy_window, \$dialog_window);
		$sel_window->signal_connect ("delete_event", \&destroy_window, \$dialog_window);
		$sel_window->set_title ("Selection Test");
		$sel_window->border_width (0);
		
		# Create the list
		
		my $vbox = new Gtk::VBox (0, 5);
		$vbox->border_width (10);
		$sel_window->vbox->pack_start ($vbox, 1, 1, 0);
		$vbox->show;
		
		my $label = new Gtk::Label "Get available targets for current selection";
		$vbox->pack_start ($label, 0, 0, 0);
		$label->show;
		
		my $scrolled_win = new Gtk::ScrolledWindow (undef, undef);
		$scrolled_win->set_policy ('automatic', 'automatic');
		$vbox->pack_start ($scrolled_win, 1, 1, 0);
		$scrolled_win->set_usize (100, 200);
		$scrolled_win->show;
		
		my $list = new Gtk::List;
		$scrolled_win->add_with_viewport ($list);
		
		$list->signal_connect ("selection_received", 
							   \&selection_test_received);
		$list->show;
		
		# and create some buttons
		my $button = new Gtk::Button "Get Targets";
		$sel_window->action_area->pack_start ($button, 1, 1, 0);
		
		$button->signal_connect ("clicked",
			 sub {
				$list->selection_convert($Gtk::Atoms{PRIMARY},$Gtk::Atoms{TARGETS}, 0);
			 });
		$button->show;
		
		$button = new Gtk::Button "Quit";
		$sel_window->action_area->pack_start ($button, 1, 1, 0);
		
		$button->signal_connect ("clicked", sub { $sel_window->destroy; } );
		$button->show;
    }
	
    if (!$sel_window->visible) {
		$sel_window->show;
    } else {
		$sel_window->destroy;
    }
}

my $timeout_count = 0;
my $timer;

sub timeout_test {
	my($label)=@_;
	$label->set( "count: " . ++$timeout_count );
	return 1;
}

sub start_timeout_test {
	my($widget, $label) = @_;
	if (!$timer) {
		$timer = Gtk->timeout_add(100, \&timeout_test, $label);
	}
}

sub stop_timeout_test {
	if (defined $timer) {
		Gtk->timeout_remove($timer);
		$timer =0 ;
	}
}

sub destroy_timeout_test {
	my($widget,$windowref)=@_;
	destroy_window($widget,$windowref);
	stop_timeout_test(undef,undef);
}

sub create_timeout_test {
	my($button,$label);
	if (not defined $timeout_window) {
		$timeout_window = new Gtk::Dialog;
		$timeout_window->signal_connect("destroy", \&destroy_timeout_test, \$timeout_window);
		$timeout_window->signal_connect("delete_event", \&destroy_timeout_test, \$timeout_window);
		$timeout_window->set_title("Timeout Test");
		$timeout_window->border_width(0);
		
		$label = new Gtk::Label("count: 0");
		$label->set_padding(10,10);
		$timeout_window->vbox->pack_start($label,1,1,0);
		$label->show;
		
		$button = new Gtk::Button "close";
		$button->signal_connect("clicked", sub { destroy $timeout_window});
		$button->can_default(1);
		$timeout_window->action_area->pack_start($button,1,1,0);
		$button->grab_default;
		$button->show;
		
		$button = new Gtk::Button "start";
		$button->signal_connect("clicked", \&start_timeout_test, $label);
		$button->can_default(1);
		$timeout_window->action_area->pack_start($button,1,1,0);
		$button->show;
		
		$button = new Gtk::Button "stop";
		$button->signal_connect("clicked", \&stop_timeout_test);
		$button->can_default(1);
		$timeout_window->action_area->pack_start($button, 1,1,0);
		$button->show;
		
	}
	
	if (!visible $timeout_window) {
		show $timeout_window;
	} else {
		destroy $timeout_window;
	}
}

sub label_toggle {
	my($widget,$widgetref) = @_;
	if (not defined $$widgetref) {
		$$widgetref = new Gtk::Label "Dialog Test";
		$$widgetref->set_padding(10, 10);
		$dialog_window->vbox->pack_start($$widgetref, 1, 1, 0);
		$$widgetref->show;
	} else {
		$$widgetref->destroy;
		$$widgetref = undef;
	}
}

sub create_dialog {
	my($label, $button);
	
	if (not defined $dialog_window) {
		$dialog_window = new Gtk::Dialog;
		$dialog_window->signal_connect("destroy", \&destroy_window, \$dialog_window);
		$dialog_window->signal_connect("delete_event", \&destroy_window, \$dialog_window);
		$dialog_window->set_title("dialog");
		$dialog_window->border_width(0);
		
		$button = new Gtk::Button "OK";
		$button->can_default(1);
		$dialog_window->action_area->pack_start($button, 1, 1, 0);
		$button->grab_default;
		$button->show;
		
		$button = new Gtk::Button "Toggle";
		$button->signal_connect("clicked", \&label_toggle, \$label);
		$button->can_default(1);
		$dialog_window->action_area->pack_start($button, 1, 1, 0);
		$button->show;
		
		$label = undef;
	}
	if (!$dialog_window->visible) {
		$dialog_window->show;
	} else {
		$dialog_window->destroy;
	}	
}

my $idle_count = 0;
my $idle;

sub idle_test {
	my($label) = @_;
	my($buffer) = "count: " . ++$idle_count;
	$label->set($buffer);
	
	return 1;
}

sub start_idle_test {
	my($widget, $label) = @_;
	if (!$idle) {
		$idle_count = 0;
		$idle = Gtk->idle_add(\&idle_test, $label);
	}
}

sub stop_idle_test {
	if ($idle) {
		Gtk->idle_remove($idle);
		$idle = 0;
	}
}

sub destroy_idle_test {
	destroy_window(@_);
	stop_idle_test(undef, undef);
}

sub create_idle_test {
	my ($button, $label);
	if (not defined $idle_window) {
		$idle_window = new Gtk::Dialog;
		signal_connect $idle_window destroy => \&destroy_idle_test, \$idle_window;
		signal_connect $idle_window delete_event => \&destroy_idle_test, \$idle_window;
		$idle_window->set_title("Idle Test");
		$idle_window->border_width(0);

		$label = new Gtk::Label "count: 0";
		$label->set_padding(10, 10);
		$idle_window->vbox->pack_start($label, 1, 1, 0);
		$label->show;
		
		$button = new Gtk::Button "close";
		$button->signal_connect("clicked", sub { $idle_window->destroy });
		$button->can_default(1);
		$idle_window->action_area->pack_start($button, 1, 1, 0);
		$button->grab_default();
		$button->show;
		
		$button = new Gtk::Button "start";
		signal_connect $button "clicked", \&start_idle_test, $label;
		$button->can_default(1);
		$idle_window->action_area->pack_start($button, 1, 1, 0);
		$button->show;
		
		$button = new Gtk::Button "stop";
		signal_connect $button "clicked", \&stop_idle_test;
		$button->can_default(1);
		$idle_window->action_area->pack_start($button, 1, 1, 0);
		$button->show;
	}
	if (!$idle_window->visible) {
		show $idle_window;
	} else {
		destroy $idle_window;
	}
}

sub mainloop_destroyed {
	my($window, $var) = @_;
	$$var = undef;
	Gtk->main_quit;
}

sub create_mainloop {
	my ($button, $label);
	if (not defined $mainloop_window) {
		$mainloop_window = new Gtk::Dialog;

		$mainloop_window->set_title("Test Main Loop");
		
		signal_connect $mainloop_window destroy => \&mainloop_destroyed, \$mainloop_window;
		
		$label = new Gtk::Label "In recursive main loop...";
		$label->set_padding(20, 20);
		
		$mainloop_window->vbox->pack_start($label, 1, 1, 0);
		$label->show;
		
		$button = new Gtk::Button "Leave";
		$mainloop_window->action_area->pack_start($button, 0, 1, 0);

		$button->signal_connect("clicked", sub { $mainloop_window->destroy });
		$button->can_default(1);
		$button->grab_default();
		$button->show;
	}
	if (!$mainloop_window->visible) {
		show $mainloop_window;
		print "create_mainloop: start\n";
		Gtk->main;
		print "create_mainloop: done\n";
	} else {
		destroy $mainloop_window;
	}
}

sub do_exit {
	Gtk->exit(0);
}

sub create_main_window {
	my(
		@buttons,
		$window,
		$box1,
		$scw,
		$box2,
		$button,
		$separator,
		$buffer,
		$label,
		$i
	);

	@buttons = (
		'button box',		\&create_button_box,
		'buttons',			\&create_buttons,
		'check buttons',	\&create_check_buttons,
		'clist',			\&create_clist,
		'color selection',	\&create_color_selection,
		'ctree',			( $gtk_1_0 ? undef : \&create_ctree ),
		'cursors',			\&create_cursors,
		'dialog',			\&create_dialog,
		'dnd',				undef, #\&create_dnd,
		'entry',			\&create_entry,
		'file selection',	\&create_file_selection,
		'font selection',	( $gtk_1_0 ? undef : \&create_font_selection ),
		'gamma curve',		\&create_gamma_curve,
		'handle box',		\&create_handlebox,
		'item factory',		\&create_item_factory,
		'list',				\&create_list,
		'menus',			\&create_menus,
		'miscellaneous',	undef,
		'notebook',			\&create_notebook,
		'panes',			\&create_panes,
		'pixmap',			\&create_pixmap,
		'preview color',	\&create_color_preview,
		'preview gray',		\&create_gray_preview,
		'progress bar',		\&create_progress_bar,
		'radio buttons',	\&create_radio_buttons,
		'range controls',	\&create_range_controls,
		'reparent',			\&create_reparent,
		'rulers',			\&create_rulers,
		'scrolled windows',	\&create_scrolled_windows,
		'shapes',			\&create_shapes,
		'spinbutton',		\&create_spins,
		'statusbar',		\&create_statusbar,
		'test idle',		\&create_idle_test,
		'test mainloop',	\&create_mainloop,
		'test scrolling',	\&create_scroll_test,
		'test selection',	\&create_selection_test,
		'test timeout',		\&create_timeout_test,
		'text',				\&create_text,
		'toggle buttons',	\&create_toggle_buttons,
		'toolbar',			\&create_toolbar_window,
		'tooltips',			\&create_tooltips,
		'tree',				\&create_tree_mode_window,
		'WM hints',			\&create_wmhints,
	);
	
	$window = new Gtk::Window('toplevel');
	$window->set_name("main window");
	$window->set_uposition(20, 20);
	$window->set_usize(200, 400);
	
	$window->signal_connect("destroy" => \&Gtk::main_quit);
	$window->signal_connect("delete_event" => \&Gtk::false);

	$box1 = new Gtk::VBox(0, 0);
	$window->add($box1);
	$box1->show;
	
	$buffer = sprintf "Gtk+ v%d.%d.%d", Gtk->major_version, Gtk->minor_version, Gtk->micro_version;
	
	$buffer .= ", Perl/Gtk+ v" . $Gtk::VERSION;
	
	$label = new Gtk::Label $buffer;
	show $label;
	$box1->pack_start($label, 0, 0, 0);

	$scw = new Gtk::ScrolledWindow(undef, undef);
	$scw->set_policy('automatic', 'automatic');
	$scw->show;
	$scw->set_border_width(10);
	
	$box1->pack_start($scw, 1, 1, 0);

	$box2 = new Gtk::VBox(0, 0);
	$box2->show;
	$box2->set_border_width(10);
	$scw->add_with_viewport($box2);
	
	for($i=0;$i<@buttons;$i+=2) {
		$button = new Gtk::Button($buttons[$i]);
		if (defined $buttons[$i+1]) {
			$button->signal_connect(clicked => $buttons[$i+1]);
		} else {
			$button->set_sensitive(0);
		}
		$box2->pack_start($button, 1, 1, 0);
		show $button;
	}
	
	$separator = new Gtk::HSeparator;
	$box1->pack_start($separator, 0, 1, 0);
	$separator->show;
	
	$box2 = new Gtk::VBox(0, 10);
	$box2->border_width(10);
	$box1->pack_start($box2, 0, 1, 0);
	$box2->show();
	
	$button = new Gtk::Button "close";
	signal_connect $button "clicked", \&do_exit;
	$box2->pack_start($button, 1, 1, 0);
	$button->can_default(1);
	$button->grab_default();
	$button->show;
	
	$window->show;
	
}

parse Gtk::Rc "testgtkrc";

create_main_window;

main Gtk;
