
use Gtk;
use Gtk::Atoms;

sub bbox_widget_destroy {
	my($widget, $todestroy) = @_;
	
}

sub destroy_tooltips {
#	print "Destroy_tooltips: ", Dumper(\@_);
	my($widget, $window) = @_;
	#$$window->{tooltips}->unref;
	$$window = undef;
}


sub cursor_expose_event {
	my($widget, $event, $data) = @_;
	my($darea, $drawable, $black_gc, $gray_gc, $white_gc, $max_width, $max_height);
	
	$darea = $widget;
	$drawable = $widget->window;
	$white_gc = $widget->style->white_gc;
	$gray_gc = $widget->style->bc_gc('normal');
	$black_gc = $widget->style->black_gc;
	$max_width = $widget->allocation->{width};
	$max_height = $widget->allocation->{width};
	
	$drawable->draw_rectangle($white_gc, 1, 0, 0, $max_width, $max_height/2);
	$drawable->draw_rectangle($black_gc, 1, 0, $max_height/2, $max_width, $max_height/2);
	$drawable->draw_rectangle($gray_gc, 1, $max_width/3, $max_height/3, $max_width/3, $max_height/3);
	
	1;
}

sub set_cursor {
	my($spinner, $widget) = @_;
	my($c, $cursor);
	
	$c = $spinner->get_value_as_int;
	$c = 0 if $c < 0;
	$c = 152 if $c > 152;
	
	$cursor = new Gtk::Gdk::Cusor $c;
	$widget->window->set_cursor($cursor);
	
}

sub cursor_event {
	my($widget,$event,$spinner) = @_;
	if ($event->{type} eq 'button-press' and ($event->{button} == 1 or $event->{button} == 3)) {
		$spinner->spin($event->{button} == 1 ? 'up' : 'down', $spinner->adjustment->step_increment);
		return 1;
	}
	return 0;
}

#static void
#create_cursors ()
#{
#  static GtkWidget *window = NULL;
#  GtkWidget *frame;
#  GtkWidget *hbox;
#  GtkWidget *main_vbox;
#  GtkWidget *vbox;
#  GtkWidget *darea;
#  GtkWidget *spinner;
#  GtkWidget *button;
#  GtkWidget *label;
#  GtkWidget *any;
#  GtkAdjustment *adj;
#
#  if (!window)
#    {
#      window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
#      
#      gtk_signal_connect (GTK_OBJECT (window), "destroy",
#                          GTK_SIGNAL_FUNC (gtk_widget_destroyed),
#                          &window);
#      
#      gtk_window_set_title (GTK_WINDOW (window), "Cursors");
#      
#      main_vbox = gtk_vbox_new (FALSE, 5);
#      gtk_container_border_width (GTK_CONTAINER (main_vbox), 0);
#      gtk_container_add (GTK_CONTAINER (window), main_vbox);
#
#      vbox =
#        gtk_widget_new (gtk_vbox_get_type (),
#                        "GtkBox::homogeneous", FALSE,
#                        "GtkBox::spacing", 5,
#                        "GtkContainer::border_width", 10,
#                        "GtkWidget::parent", main_vbox,
#                        "GtkWidget::visible", TRUE,
#                        NULL);
#
#      hbox = gtk_hbox_new (FALSE, 0);
#      gtk_container_border_width (GTK_CONTAINER (hbox), 5);
#      gtk_box_pack_start (GTK_BOX (vbox), hbox, FALSE, TRUE, 0);
#      
#      label = gtk_label_new ("Cursor Value:");
#      gtk_misc_set_alignment (GTK_MISC (label), 0, 0.5);
#      gtk_box_pack_start (GTK_BOX (hbox), label, FALSE, TRUE, 0);
#      
#      adj = (GtkAdjustment *) gtk_adjustment_new (0,
#                                                  0, 152,
#                                                  2,
#                                                  10, 0);
#      spinner = gtk_spin_button_new (adj, 0, 0);
#      gtk_box_pack_start (GTK_BOX (hbox), spinner, TRUE, TRUE, 0);
#
#      frame =
#        gtk_widget_new (gtk_frame_get_type (),
#                        "GtkFrame::shadow", GTK_SHADOW_ETCHED_IN,
#                        "GtkFrame::label_xalign", 0.5,
#                        "GtkFrame::label", "Cursor Area",
#                        "GtkContainer::border_width", 10,
#                        "GtkWidget::parent", vbox,
#                        "GtkWidget::visible", TRUE,
#                        NULL);
#
#      darea = gtk_drawing_area_new ();
#      gtk_widget_set_usize (darea, 80, 80);
#      gtk_container_add (GTK_CONTAINER (frame), darea);
#      gtk_signal_connect (GTK_OBJECT (darea),
#                          "expose_event",
#                          GTK_SIGNAL_FUNC (cursor_expose_event),
#                          NULL);
#      gtk_widget_set_events (darea, GDK_EXPOSURE_MASK | GDK_BUTTON_PRESS_MASK);
#      gtk_signal_connect (GTK_OBJECT (darea),
#                          "button_press_event",
#                          GTK_SIGNAL_FUNC (cursor_event),
#                          spinner);
#      gtk_widget_show (darea);
#
#      gtk_signal_connect (GTK_OBJECT (spinner), "changed",
#                          GTK_SIGNAL_FUNC (set_cursor),
#                          darea);
#
#      any =
#        gtk_widget_new (gtk_hseparator_get_type (),
#                        "GtkWidget::visible", TRUE,
#                        NULL);
#      gtk_box_pack_start (GTK_BOX (main_vbox), any, FALSE, TRUE, 0);
#  
#      hbox = gtk_hbox_new (FALSE, 0);
#      gtk_container_border_width (GTK_CONTAINER (hbox), 10);
#      gtk_box_pack_start (GTK_BOX (main_vbox), hbox, FALSE, TRUE, 0);
#
#      button = gtk_button_new_with_label ("Close");
#      gtk_signal_connect_object (GTK_OBJECT (button), "clicked",
#                                 GTK_SIGNAL_FUNC (gtk_widget_destroy),
#                                 GTK_OBJECT (window));
#      gtk_box_pack_start (GTK_BOX (hbox), button, TRUE, TRUE, 5);
#
#      gtk_widget_show_all (window);
#
#      set_cursor (spinner, darea);
#    }
#  else
#    gtk_widget_destroy (window);
#}



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

$spinner1 = undef;

sub toggle_snap {
	my($widget, $spin) = @_;
	
	if ($widget->active) {
		$spin->set_update_policy(['always', 'snap_to_ticks']);
	} else {
		$spin->set_update_policy('always');
	}
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
	my($labels, $spin, $buf);
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
		$button->set_state(1);
		
		$button = new Gtk::CheckButton "Numeric only input mode";
		$button->signal_connect(clicked => \&toggle_numeric, $spinner1);
		$vbox->pack_start($button, 1, 1, 0);
		$button->set_state(1);
		
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
	
	return if $event->{type} ne 'button_press';
	
	$widget->{save_x} = $event->{x};
	$widget->{save_y} = $event->{y};
	
	$widget->grab_add;
	$w = $widget->window;
	Gtk::Gdk->pointer_grab($w, 1, 
		['button_release_mask', 'button_motion_mask', 'pointer_motion_hint_mask'], 
		undef, undef ,0);
}

sub shape_released {
	my($widget) = @_;
	$widget->grab_remove;
	Gtk::Gdk->pointer_ungrab(0);
}

sub shape_motion {
	my($widget, $event) = @_;
	
	($x,$y) = $root_win->get_pointer;
	$widget->set_uposition($x - $widget->{save_x}, $y - $widget->{save_y});
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
	
	$window->set_events( [@{$window->get_events}, 'button_motion_mask', 'pointer_motion_hint_mask', 'button_press_mask']);
	
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
		$modeller = shape_create_icon("Modeller.xpm", 440, 140, 0,0, -popup);
		$modeller->signal_connect("destroy", \&Gtk::Widget::destroyed, \$modeller);
	} else {
		destroy $modeller;
	}

	if (not defined $sheets) {
		$sheets = shape_create_icon("FilesQueue.xpm", 580,170, 0,0, -popup);
		$sheets->signal_connect("destroy", \&Gtk::Widget::destroyed, \$sheets);
	} else {
		destroy $sheets;
	}

	if (not defined $rings) {
		$rings = shape_create_icon("3DRings.xpm", 460, 270, 25,25, -toplevel);
		$rings->signal_connect("destroy", \&Gtk::Widget::destroyed, \$rings);
	} else {
		destroy $rings;
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
		$button->set_state(1);
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
	my ($window, $color, $toolbar, $entry);

	$toplevel->realize unless $toplevel->realized;

	$window = $toplevel->window;
	$color = $toplevel->style->bg('normal');
	
	$toolbar = new Gtk::Toolbar('horizontal', 'both');
	$button = $toolbar->append_item ( "Horizontal", "Horizontal toolbar layout",
		"Toolbar/Horizontal", new_pixmap("test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_orientation('horizontal')});
	$button = $toolbar->append_item( "Vertical","Vertical toolbar layout",
		"Toolbar/Vertical", new_pixmap("test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_orientation('vertical')});

	$toolbar->append_space();

	$button = $toolbar->append_item( "Icons","Only show toolbar icons",
		"Toolbar/IconsOnly", new_pixmap("test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_style('icons')});
	$button = $toolbar->append_item( "Text","Only show toolbar text",
		"Toolbar/TextOnly", new_pixmap("test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_style('text')});
	$button = $toolbar->append_item( "Both","Show toolbar icons and text",
		"Toolbar/Both", new_pixmap("test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_style('both')});

	$toolbar->append_space;

	$entry = new Gtk::Entry;
	$entry->set_text("Abracadabra");
	$entry->set_max_length(3);
	$entry->show;
	$toolbar->append_widget($entry, "This is an unusable GtkEntry ;)", "Hey don't click me!!!");

	$button = $toolbar->append_item( "Small","Use small spaces",
		"Toolbar/Small",, new_pixmap("test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_space_size(5)});
	$button = $toolbar->append_item( "Big","Use big spaces",
		"Toolbar/Big", new_pixmap("test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_space_size(10)});

	$toolbar->append_space();

	$button = $toolbar->append_item( "Enable","Enable tooltips",
		undef, new_pixmap("test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_tooltips(1)});
	$button = $toolbar->append_item( "Disable","Disable tooltips",
		undef, new_pixmap("test.xpm",$window, $color));
	$button->signal_connect('clicked', sub {$toolbar->set_tooltips(0)});

	$toolbar;
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

$statusbar_counter = 1;

sub statusbar_push {
	my($widget, $statusbar) = @_;
	$statusbar->push(1, "Something ".($statusbar_counter++));
}

sub statusbar_pop {
	my($widget, $statusbar) = @_;
	$statusbar->pop(1);
}

sub statusbar_steal {
	my($widget, $statusbar) = @_;
	$statusbar->remove(1,4);
}

sub statusbar_popped {
	my($statusbar, $context_id, $text) = @_;
	if (!$statusbar->messages) {
		$statusbar_counter = 1;
	}
}

sub statusbar_contexts {
	my($button, $statusbar) = @_;
	
	foreach $string ("any context", "idle messages", "some text", "hit the mouse", "hit the mouse2") {
		print "Gtk::StatusBar: context = \"$string\", context_id=", $statusbar->get_context_id($string),"\n";
	}
}

sub statusbar_dump_stack {
	my($button, $statusbar) = @_;
	
	foreach $msg ($statusbar->messages) {
		print "context_id: $msg{context_id}, message_id: $msg{message_id}, status_text: \"$msg{text}\"\n";
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
		
		$button = new Gtk::Button "switch";
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

		($pixmap,$mask) = Gtk::Gdk::Pixmap->create_from_xpm($pixmap_window->window, $style->bg('normal'), "test.xpm");
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
		print "1\n";
		$tt_window = new Gtk::Widget "Gtk::Window",
							type => -toplevel,
							border_width => 0,
							title => "Tooltips",
							allow_shrink => 1,
							allow_grow => 0,
							auto_shrink => 1,
							width => 200,
							signal::destroy => [\&destroy_tooltips, \$tt_window];

		print "2\n";
		
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
		
		Gtk::Object::set($tips_query,visible => 1,
						parent => $box3,
						caller => $button,
						widget_entered => sub {tips_query_widget_entered @_, $toggle}, # [\&tips_query_widget_entered, $toggle],
						widget_selected => \&tips_query_widget_selected);
		
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
		$scrolled_window->add($table);
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

		#$cb = new Gtk::ComboBox;
		#$cb->set_text('hello world');
		#$cb->select_region(0, length($cb->get_text));
		#$cb->set_popdown_strings('item1', 'item2', 'and item3');
		#$cb->show;
		#$box2->pack_start($cb, 1, 1, 0);

		$editable = new Gtk::CheckButton('Editable');
		$editable->signal_connect('toggled', sub {$entry->set_editable($_[0]->active)});
		$editable->set_state(1);
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
		"hello",
	    "world",
	    "blah",
	    "foo",
	    "bar",
	    "argh",
	    "spencer",
	    "is a",
	    "wussy",
	    "programmer",
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
		$scrolled_win->add($list);
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


# FIXME: clist signal handling..
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

		$clist = new Gtk::CList($#titles);
		
		$button = new Gtk::Button('Add 1,000 Rows');
		$button->show;
		$button->signal_connect('clicked', \&add1000_clist); # FIXME
		$box2->pack_start($button, 1, 1, 0);

		$button = new Gtk::Button('Add 10,000 Rows');
		$button->show;
		$button->signal_connect('clicked', \&add10000_clist);
		$box2->pack_start($button, 1, 1, 0);

		$button = new Gtk::Button('Clear list');
		$button->show;
		$button->signal_connect('clicked', sub {$clist->clear; $clist_rows = 0;});
		$box2->pack_start($button, 1, 1, 0);

		$button = new Gtk::Button('Remove Row');
		$button->show;
		$button->signal_connect('clicked', sub {$clist->remove_row(0); $clist_rows--;});
		$box2->pack_start($button, 1, 1, 0);

		$box2 = new Gtk::VBox(0, 10);
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;

		$clist->set_row_height(20);

		for $i ( 1 .. scalar(@titles) - 1 ) {
			$clist->set_column_width($i, 80);
		}
		$clist->set_selection_mode('browse');
		$clist->set_policy ('automatic', 'automatic');
		$clist->set_column_justification(1, 'right');
		$clist->set_column_justification(2, 'left');

		for $i ( 0 .. scalar(@titles) - 1 ) {
			$text[$i] = "Column $i";
		}
		$text[1] = 'Right';
		$text[2] = 'Center';
		shift( @text );
		# FIXME
		for  $i ( 0 .. 100 ) {
			$clist->append("Row $i", @text);
		}

		$clist->border_width(5);
		$box2->pack_start($clist, 1, 1, 0);
		$clist->show;

		$separator = new Gtk::HSeparator;
		$separator->show;
		$box1->pack_start($separator, 0, 1, 0);

		$box2 = new Gtk::VBox(0, 10);
		$box2->border_width(10);
		$box1->pack_start($box2, 1, 1, 0);
		$box2->show;

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
		$table->attach_defaults($text, 0,1,0,1);
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

@book_open_xpm = (
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

@book_closed_xpm = (
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

sub page_switch {
	my($widget, $page, $page_num) = @_;
	my($oldpage, $pixwid);

	$oldpage = $widget->cur_page;
	
	print "page_switch: new_page=$page, old_page=$oldpage, page_num=$page_num\n";
	
	return if ($page == $oldpage);
	
	print "p0=$page\n";
	$p1 = $page->tab_label;
	print "p1=$p1\n";
	@c = $p1->children;
	print "Children = ",join(",", @c),"\n";
	$p2 = $c[0];
	print "p2=$p2\n";
	$p3 = $p2->widget;
	print "p3=$p3\n";
	$pixwid = $p3;

	#$pixwid = ($page->tab_label->children)[0]->widget;
	$pixwid->set($book_open, $book_open_mask);
	#$pixwid = ($page->menu_label->children)[0]->widget;
	#$pixwid->set($book_open, $book_open_mask);
	
	if ($oldpage) {
		$pixwid = ($page->tab_label->children)[0]->widget;
		$pixwid->set($book_closed, $book_closed_mask);
		#$pixwid = ($page->menu_label->children)[0]->widget;
		#$pixwid->set($book_closed, $book_closed_mask);
	}
	
}

#static void
#page_switch (GtkWidget *widget, GtkNotebookPage *page, gint page_num)
#{
#  GtkNotebookPage *oldpage;
#  GtkWidget *pixwid;
#
#  oldpage = GTK_NOTEBOOK (widget)->cur_page;
#
#  if (page == oldpage)
#    return;
#
#  pixwid = ((GtkBoxChild*)(GTK_BOX (page->tab_label)->children->data))->widget;
#  gtk_pixmap_set (GTK_PIXMAP (pixwid), book_open, book_open_mask);
#  pixwid = ((GtkBoxChild*) (GTK_BOX (page->menu_label)->children->data))->widget;
#  gtk_pixmap_set (GTK_PIXMAP (pixwid), book_open, book_open_mask);
#
#  if (oldpage)
#    {
#      pixwid = ((GtkBoxChild*) (GTK_BOX 
#                                (oldpage->tab_label)->children->data))->widget;
#      gtk_pixmap_set (GTK_PIXMAP (pixwid), book_closed, book_closed_mask);
#      pixwid = ((GtkBoxChild*) (GTK_BOX (oldpage->menu_label)->children->data))->widget;
#      gtk_pixmap_set (GTK_PIXMAP (pixwid), book_closed, book_closed_mask);
#    }
#}



sub create_pages {
	my($notebook, $start, $end) = @_;
	
	my($child, $label, $entry, $box, $hbox, $label_box, $menu_box, $button, $pixwid);
	my($i, $buffer);
	
	for ($i=$start; $i <= $end; $i++) {
		$buffer = "Page $i";
		
		if ((i % 4) == 3) {
			$child = new Gtk::Button $buffer;
			$child->border_width(10);
		} elsif((i % 4) == 2) {
			$child = new Gtk::Label $buffer;
		} elsif((i % 4) == 1) {
			$child = new Gtk::Frame $buffer;
			$child->border_width(10);
			
			$box = new Gtk::VBox 1, 0;
			$box->border_width(10);
			$child->add($box);
			
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
			$child = new Gtk::Frame $buffer;
			$child->border_width(10);
			
			$label = new Gtk::Label $buffer;
			$child->add($label);
		}
		
		show_all $child;
		
		$label_box = new Gtk::HBox 0, 0;
		$pixwid = new Gtk::Pixmap $book_closed, $book_closed_mask;
		$label_box->pack_start($pixwid, 0, 1, 0);
		$pixwid->set_padding(3, 1);
		$label = new Gtk::Label $buffer;
		$label_box->pack_start($label, 0, 1, 0);
		show_all $label_box;
		
		$menu_box = new Gtk::HBox 0, 0;
		$pixwid = new Gtk::Pixmap $book_closed, $book_closed_mask;
		$menu_box ->pack_start($pixwid, 0, 1, 0);
		$pixwid->set_padding(3,1);
		$label = new Gtk::Label $buffer;
		$menu_box->pack_start($label, 0, 1, 0);
		show_all $menu_box;
		
		$notebook->append_page_menu($child, $label_box, $menu_box);
		
	}
	
}

sub rotate_notebook {
	my($button, $notebook) = @_;
	my(%rotate) = (top => "right", right => "bottom", bottom => "left", left => "top");
	$notebook->set_tab_pos($rotate{$notebook->tab_pos});
}

sub standard_notebook {
	my($button, $notebook) = @_;
	
	$notebook->set_show_tabs(1);
	$notebook->set_scrollable(0);
	if ($notebook->children == 15) {
		my($i);
		for($i=0;$i<10;$i++) {
			$notebook->remove_page(5);
		}
	}
}

sub notabs_notebook {
	my($button, $notebook) = @_;
	$notebook->set_show_tabs(0);
	if ($notebook->children == 15) {
		my($i);
		for($i=0;$i<10;$i++) {
			$notebook->remove_page(5);
		}
	}
}

sub scrollable_notebook {
	my($button, $notebook) = @_;
	$notebook->set_show_tabs(1);
	$notebook->set_scrollable(1);
	if ($notebook->children == 5) {
		create_pages($notebook, 6, 15);
	}
}

sub notebook_popup {
	my($button, $notebook) = @_;
	if ($button->active) {
		$notebook->popup_enable;
	} else {
		$notebook->popup_disable;
	}
}

sub create_notebook {
	my($box1, $box2, $button, $separator, $notebook, $omenu, $menu, $submenu, $menuitem, $group, $transparent);
	
	if (not defined $notebook_window) {
		$notebook_window = new Gtk::Window -toplevel;
		
		$notebook_window->signal_connect("destroy", \&Gtk::Widget::destroyed, \$notebook_window);
		$notebook_window->set_title("notebook");
		$notebook_window->border_width(0);
		
		$box1 = new Gtk::VBox 0, 0;
		$notebook_window->add($box1);
		
		$notebook = new Gtk::Notebook;
		$notebook->signal_connect("switch_page", \&page_switch);
		$notebook->set_tab_pos(-top);
		$box1->pack_start($notebook, 1, 1, 0);
		$notebook->border_width(10);
		
		$notebook->realize;
		($book_open, $book_open_mask) = Gtk::Gdk::Pixmap->create_from_xpm_d($notebook->window, $transparent, @book_open_xpm);
		($book_closed, $book_closed_mask) = Gtk::Gdk::Pixmap->create_from_xpm_d($notebook->window, $transparent, @book_closed_xpm);
		
		create_pages($notebook, 1, 5);
		
		$separator = new Gtk::HSeparator;
		$box1->pack_start($separator, 0, 1, 10);
		
		$box2 = new Gtk::HBox 1, 5;
		$box1->pack_start($box2, 0, 1, 0);
		
		$omenu = new Gtk::OptionMenu;
		$menu = new Gtk::Menu;
		$submenu = undef;
		$menuitem = undef;
		
		$menuitem = new Gtk::RadioMenuItem "Standard", $menuitem;
		$menuitem->signal_connect("activate", \&standard_notebook, $notebook);
		$menu->append($menuitem);
		$menuitem->show;

		$menuitem = new Gtk::RadioMenuItem "w/o Tabs", $menuitem;
		$menuitem->signal_connect("activate", \&notabs_notebook, $notebook);
		$menu->append($menuitem);
		$menuitem->show;

		$menuitem = new Gtk::RadioMenuItem "Scrollable", $menuitem;
		$menuitem->signal_connect("activate", \&scrollable_notebook, $notebook);
		$menu->append($menuitem);
		$menuitem->show;
		
		$omenu->set_menu($menu);
		$box2->pack_start($omenu, 0, 0, 0);
		$button = new Gtk::CheckButton "enable popup menu";
		$box2->pack_start($button, 0, 0, 0);
		$button->signal_connect("clicked", \&notebook_popup, $notebook);
		
		$box2 = new Gtk::HBox 0, 10;
		$box2->border_width(10);
		$box1->pack_start($box2, 0, 1, 0);
		
		$button = new Gtk::Button "close";
		$button->signal_connect("clicked", sub {$notebook_window->destroy});
		$box2->pack_start($button, 1, 1, 0);
		$button->can_default(1);
		$button->grab_default;
		
		$button = new Gtk::Button "next";
		$button->signal_connect("clicked", sub {$notebook->next_page});
		$box2->pack_start($button, 1, 1, 0);
		
		$button = new Gtk::Button "prev";
		$button->signal_connect("clicked", sub {$notebook->prev_page});
		$box2->pack_start($button, 1, 1, 0);

		$button = new Gtk::Button "rotate";
		$button->signal_connect("clicked", \&rotate_notebook, $notebook);
		$box2->pack_start($button, 1, 1, 0);
		
		
	}
	
	if (! $notebook_window->visible) {
		$notebook_window->show_all;
	} else {
		$notebook_window->destroy;
	}
}



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

sub progress_timeout {
	my($progressbar) = @_;
	my($new_val) = $progressbar->percentage;
	if ($new_val>=1.0) {
		$new_val = 0.0;
	}
	$new_val += 0.02;
	
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
		
		$progress_timer = Gtk->timeout_add(100, \&progress_timeout, $pbar);
		
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
	
	destroy_window($window, $windowref);
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
	
	destroy_window($window, $windowref);
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
	my($curve,@vec,$i,$max);

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
		$scrolled_win->add ($list);
		
		$list->signal_connect ("selection_received", 
							   \&selection_test_received);
		$list->show;
		
		# and create some buttons
		my $button = new Gtk::Button "Get Targets";
		$sel_window->action_area->pack_start ($button, 1, 1, 0);
		
		$button->signal_connect ("clicked",
			 sub {
				 $list->selection_convert ($Gtk::Atoms{PRIMARY},$Gtk::Atoms{TARGETS}, 0);
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

my($timeout_count)=0;
sub timeout_test {
	my($label)=@_;
	$label->set("count: ".++$timeout_count);
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

sub idle_test {
	my($label) = @_;
	my($buffer) = "count: ".++$idle_count;
	$label->set($buffer);
	
	return 1;
}

sub start_idle_test {
	my($widget, $label) = @_;
	if (!$idle) {
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

sub test_destroy {
	my($widget, $windowref) = @_;
	destroy_window($widget, $windowref);
	Gtk->main_quit;
}

sub create_test {
	if (not defined $test_window) {
		$test_window = new Gtk::Window("toplevel");
		$test_window->signal_connect("destroy" => \&test_destroy, \$test_window);
		$test_window->signal_connect("delete_event" => \&test_destroy, \$test_window);
		$test_window->set_title("test");
		$test_window->border_width(0);
	}
	if (!$test_window->visible) {
		$test_window->show;
		Gtk->print("create_test: start\n");
		Gtk->main;
		Gtk->print("create_test: done\n");
	} else {
		$test_window->destroy;
	}
}

sub do_exit {
	Gtk->exit(0);
}

sub create_main_window {
	my(@buttons,$window,$box1,$scw, $box2,$button,$separator, $buffer, $label);
	@buttons = (
		"button box", \&create_button_box,
		"buttons",	\&create_buttons,
		"toggle buttons", \&create_toggle_buttons,
		"radio buttons", \&create_radio_buttons,
		"toolbar", \&create_toolbar_window,
		"handlebox", \&create_handlebox,
		"reparent", \&create_reparent,
		"pixmap", \&create_pixmap,
		"create tooltips", \&create_tooltips,
		"menus", \&create_menus,
		"create scrolled windows", \&create_scrolled_windows,
		"drawing areas", undef,
		"entry", \&create_entry,
		"list", \&create_list,
		"clist", \&create_clist,
		"color selection", \&create_color_selection,
      	"file selection", \&create_file_selection,
      	"range controls", \&create_range_controls,
      	"rulers", \&create_rulers,
      	"shapes", \&create_shapes,
		"text", \&create_text,
      	"notebook", \&create_notebook,
      	"panes", \&create_panes,
      	"progress bar", \&create_progress_bar,
      	"color preview", \&create_color_preview,
      	"gray preview", \&create_gray_preview,
		"dialog",	\&create_dialog,
      	"gamma curve", \&create_gamma_curve,
		"test selection", \&create_selection_test,
		"test timeout", \&create_timeout_test,
		"spinbutton", \&create_spins,
		"statusbar", \&create_statusbar,
		"test idle", \&create_idle_test,
		"create test",	\&create_test,
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
	
	$buffer = sprintf "Gtk+ v%d.%d", Gtk->major_version, Gtk->minor_version;
	
	if (Gtk->micro_version > 0) {
		$buffer .= sprintf ".%d", Gtk->micro_version;
	}
	
	$label = new Gtk::Label $buffer;
	show $label;
	$box1->pack_start($label, 0, 0, 0);

	$scw = new Gtk::ScrolledWindow(undef, undef);
	$scw->set_policy('automatic', 'automatic');
	$scw->show;
	$scw->border_width(10);
	
	$box1->pack_start($scw, 1, 1, 0);

	$box2 = new Gtk::VBox(0, 0);
	$box2->show;
	$box2->border_width(10);
	$scw->add($box2);
	
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
