#!/usr/bin/perl
# vim: set ft=perl :
#
# $Id$
#

use warnings;
use strict;
use Gtk2::TestHelper tests => 158;

# we can't instantiate Gtk2::Widget, it's abstract.  use a button instead.

my $widget = Gtk2::Widget->new ('Gtk2::Button', label => 'Test');

isa_ok( $widget, Gtk2::Widget::, 'we can create widgets' );

## begin item by item check
$widget->set (name => 'foo');
is ($widget->get ('name'), 'foo', '$widget->set|get single');

$widget->set (name => 'foo', height_request => 3);
ok (eq_array ([$widget->get ('name', 'height-request')],
	      ['foo', 3]), '$widget->set|get multiple');

$widget->set_name ('bar');
is ($widget->get ('name'), 'bar', '$widget->set_name');

my $win = Gtk2::Window->new;
$win->realize;

$widget->set_parent ($win);
is ($widget->get ('parent'), $win);

$widget->set_parent_window ($win->window);
is ($widget->get_parent_window, $win->window);

$widget->reparent ($win);
is ($widget->get ('parent'), $win);

$widget->unparent;
is ($widget->get ('parent'), undef, '$widget->unparent');

is( $widget->get_parent, undef );
is( $widget->parent, undef );

$widget->show;
ok ($widget->get ('visible'), '$widget->show');
$widget->hide;
ok ($widget->get ('visible') == 0, '$widget->hide');
$widget->show_now;
ok ($widget->get ('visible'), '$widget->show_now');
$widget->hide_all;
ok ($widget->get ('visible') == 0, '$widget->hide');
$widget->show_all;
ok ($widget->get ('visible') == 1, '$widget->hide');

# we need to parent this widget for tests below,
$win = Gtk2::Widget->new ('Gtk2::Window');
$win->add ($widget);
print 'trying: $widget->map'."\n";
$widget->map;
print 'trying: $widget->unmap'."\n";
$widget->unmap;
print 'trying: $widget->realize;'."\n";
$widget->realize;
print 'trying: $widget->unrealize;'."\n";
$widget->unrealize;
print 'trying: $widget->queue_draw;'."\n";
$widget->queue_draw;
print 'trying: $widget->queue_resize;'."\n";
$widget->queue_resize;
print 'trying: $widget->activate;'."\n";
$widget->activate;
print 'trying: $widget->ensure_style;'."\n";
$widget->ensure_style;
print 'trying: $widget->reset_rc_styles;'."\n";
$widget->reset_rc_styles;
print 'trying: $widget->push_colormap;'."\n";
$widget->push_colormap (Gtk2::Gdk::Colormap->get_system);
print 'trying: $widget->pop_colormap;'."\n";
$widget->pop_colormap;
ok (1, '$widget->all-of-^the^-above');

is (ref $widget->size_request, 'Gtk2::Requisition', '$widget->size_request');
is (ref $widget->get_child_requisition, 'Gtk2::Requisition',
	'$widget->get_child_requisition');

$widget->size_allocate (Gtk2::Gdk::Rectangle->new (5, 5, 100, 100));

use Gtk2::Gdk::Keysyms;

my $accel_group = Gtk2::AccelGroup->new;
$widget->add_accelerator ("activate", $accel_group, $Gtk2::Gdk::Keysyms{ Return }, qw/shift-mask/, qw/visible/);
$widget->set_accel_path ("<gtk2perl>/Bla", $accel_group);
$widget->set_accel_path (undef,undef);
$widget->remove_accelerator ($accel_group, $Gtk2::Gdk::Keysyms{ Return }, qw/shift-mask/);

isa_ok ($widget->intersect (Gtk2::Gdk::Rectangle->new (0, 0, 10000, 10000)),
	'Gtk2::Gdk::Rectangle');

isa_ok ($widget->region_intersect (Gtk2::Gdk::Region->new ()),
	'Gtk2::Gdk::Region');

$widget->grab_focus;
ok ($widget->is_focus, '$widget->grab_focus|is_focus');
ok (!$widget->has_focus, '$widget->grab_focus|has_focus');

$widget->can_default (1);
$widget->grab_default;

$widget->set_name ("bla!");
is ($widget->get_name, "bla!");

$widget->set_state ('active');
is ($widget->state, 'active', '$widget->set_state|state');
is ($widget->saved_state, 'normal', '$widget->saved_state');

$widget->set_sensitive (0);
is ($widget->sensitive, '', '$widget->set_sensitive|sensitive false');
$widget->set_sensitive (1);
is ($widget->sensitive, 1, '$widget->set_sensitive|sensitive true');

$widget->set_events ([qw/leave-notify-mask all-events-mask/]);
ok ($widget->get_events >= [qw/leave-notify-mask all-events-mask/],
	'$widget->set_events|get_events');
$widget->add_events ([qw/button-press-mask/]);
ok ($widget->get_events >=
	[qw/button-press-mask leave-notify-mask all-events-mask/],
	'$widget->add_events|get_events');

$widget->set_extension_events ('cursor');
is ($widget->get_extension_events, 'cursor',
	'$widget->set_extension_events|get_extension_events');

is (ref $widget->get_toplevel, 'Gtk2::Window', '$widget->get_toplevel');
is (ref $widget->get_ancestor ('Gtk2::Window'), 'Gtk2::Window', 
	'$widget->get_ancestor');

$widget->set_colormap (Gtk2::Gdk::Colormap->get_system);
is (ref $widget->get_colormap, 'Gtk2::Gdk::Colormap', 
	'$widget->set_colormap|get_colormap');
$widget->set_default_colormap (Gtk2::Gdk::Colormap->get_system);
is (ref $widget->get_default_colormap, 'Gtk2::Gdk::Colormap', 
	'$widget->set_default_colormap|get_default_colormap');

is (ref $widget->get_visual, 'Gtk2::Gdk::Visual', '$widget->get_visual');
is (ref $widget->get_default_visual, 'Gtk2::Gdk::Visual', '$widget->get_visual');

# TODO: should this be -1?
is (scalar ($widget->get_pointer), -1, '$widget->get_pointer');

is ($widget->is_ancestor (Gtk2::Window->new), '', 
	'$widget->is_ancestor, false');
is ($widget->is_ancestor ($win), 1, '$widget->is_ancestor, true');

$widget->realize;
my @new = $widget->translate_coordinates ($win, 10, 10);
is (@new, 2, '$widget->translate_coordinates');

my $style = Gtk2::Style->new;

$widget->set_style ($style);
is ($widget->get_style, $style, '$widget->get_style');
is (ref $widget->get_default_style, 'Gtk2::Style', 
	'$widget->get_default_style');

$widget->set_direction ('rtl');
is ($widget->get_direction, 'rtl', '$widget->set_direction|get_direction, rtl');
$widget->set_direction ('ltr');
is ($widget->get_direction, 'ltr', '$widget->set_direction|get_direction, ltr');
$widget->set_default_direction ('rtl');
is ($widget->get_default_direction, 'rtl', 
	'$widget->set_default_direction|get_default_direction, rtl');
$widget->set_default_direction ('ltr');
is ($widget->get_default_direction, 'ltr', 
	'$widget->set_default_direction|get_default_direction, ltr');

is_deeply ([$widget->path], ["GtkWindow.bla!", "!alb.wodniWktG"]);
is_deeply ([$widget->class_path], ["GtkWindow.GtkButton", "nottuBktG.wodniWktG"]);

$widget->composite_child (1);
$widget->set_composite_name ("Bla!");
is ($widget->get_composite_name, "Bla!");

Gtk2->grab_add ($widget);
is( Gtk2->grab_get_current, $widget, 'grabbing worked' );
Gtk2->grab_remove ($widget);

$widget->realize;

$win = $widget->window;
isa_ok( $win, "Gtk2::Gdk::Window" );
$widget->window (undef);
is( $widget->window, undef );
$widget->window ($win);
is( $widget->window, $win );

my $rec = $widget->requisition;
isa_ok ($rec, 'Gtk2::Requisition');
is ($rec->width, $widget->requisition->width);
is ($rec->height, $widget->requisition->height);

my $all = $widget->allocation;
isa_ok ($all, 'Gtk2::Gdk::Rectangle');
is ($all->x, $widget->allocation->x);
is ($all->y, $widget->allocation->y);
is ($all->width, $widget->allocation->width);
is ($all->height, $widget->allocation->height);

isa_ok ($widget->style, 'Gtk2::Style');
isa_ok ($widget->parent, 'Gtk2::Window');

$widget->event (Gtk2::Gdk::Event->new ("button-press"));

## end item by item check


#
# widget flags stuff
# there are two ways to retrieve flags and two ways to set them; compare
# both, to ensure that they are always in sync.
#

$widget = Gtk2::Widget->new ('Gtk2::DrawingArea', name => 'test widget');

my $flags = $widget->get_flags;
print "flags $flags\n";

$widget->set_flags (['can-focus', 'app-paintable']);

$flags = $widget->get_flags;

ok( $flags >= 'can-focus', 'we set flags successfully' );
ok( $widget->can_focus, 'we can read flags correctly' );
ok( $widget->get ('can-focus'), 'this one also has a property, value match?' );

$widget->can_focus (0);

$flags = $widget->flags;
$flags = $widget->get_flags;

ok( !($flags & 'can-focus'), '$flags & can-focus');
ok( !$widget->can_focus, '!$widget->can_focus');
ok( !$widget->get ('can-focus'), '!$widget->get (can-focus)');

$widget->unset_flags (['app-paintable', 'sensitive']);

# alternate syntax for get_flags
$flags = $widget->flags;
ok (!($flags & 'app-paintable'), '$flags & app-paintable' );
ok (!($flags & 'sensitive'), '$flags & sensitive');
ok (!$widget->app_paintable, '$widget->app_paintable');
ok (!$widget->sensitive, '$widget->sensitive');

print "flags $flags\n";

is( $widget->allocation->x, -1 );
is( $widget->allocation->y, -1 );
is( $widget->allocation->width, 1 );
is( $widget->allocation->height, 1 );

$widget->destroy;

my $requisition = Gtk2::Requisition->new;
isa_ok( $requisition, "Gtk2::Requisition");
is( $requisition->width (5), 0 );
is( $requisition->height (5), 0 );
is( $requisition->width, 5 );
is( $requisition->height, 5 );

$requisition = Gtk2::Requisition->new (5, 5);
isa_ok( $requisition, "Gtk2::Requisition" );
is( $requisition->width, 5 );
is( $requisition->height, 5 );

foreach (qw(toplevel
            no_window
            realized
            mapped
            visible
            sensitive
            parent_sensitive
            can_focus
            has_focus
            can_default
            has_default
            has_grab
            rc_style
            composite_child
            app_paintable
            receives_default
            double_buffered)) {
	$widget->$_ (1);
	is ($widget->$_, 1);

	$widget->$_ (0); # to avoid strange segfaults
}

ok (!$widget->drawable);
ok (!$widget->is_sensitive);

my $rc_style = Gtk2::RcStyle->new;

$widget->modify_style ($rc_style);
isa_ok ($widget->get_modifier_style, "Gtk2::RcStyle");

my $black = Gtk2::Gdk::Color->new (0, 0, 0);

$widget->modify_fg (qw/normal/, $black);
$widget->modify_bg (qw/normal/, $black);
$widget->modify_text (qw/normal/, $black);
$widget->modify_base (qw/normal/, $black);
$widget->modify_font (Gtk2::Pango::FontDescription->from_string ("Sans"));

# passing undef allows you to undo
$widget->modify_fg (qw/normal/, undef);
$widget->modify_bg (qw/normal/, undef);
$widget->modify_text (qw/normal/, undef);
$widget->modify_base (qw/normal/, undef);
$widget->modify_font (undef);

isa_ok ($widget->create_pango_context, "Gtk2::Pango::Context");
isa_ok ($widget->get_pango_context, "Gtk2::Pango::Context");
isa_ok ($widget->create_pango_layout ("Bla"), "Gtk2::Pango::Layout");
isa_ok ($widget->create_pango_layout(), "Gtk2::Pango::Layout");
isa_ok ($widget->render_icon ("gtk-open", "menu", "detail"), "Gtk2::Gdk::Pixbuf");

Gtk2::Widget->push_composite_child;
Gtk2::Widget->pop_composite_child;

$win = Gtk2::Window->new;
my $box = Gtk2::VBox->new (TRUE, 0);

$box->add ($widget);
$win->add ($box);

$widget->realize;

$widget->queue_draw_area (0, 0, 10, 10);
$widget->reset_shapes;

$widget->set_app_paintable (1);
$widget->set_double_buffered (1);
$widget->set_redraw_on_allocate (1);

my $adjustment = Gtk2::Adjustment->new (0, 0, 100, 1, 5, 10);
$widget->set_scroll_adjustments ($adjustment, $adjustment);

$widget->mnemonic_activate (1);

SKIP: {
  skip "can't implement style_get without gtk_widget_class_find_style_property, which wasn't available till gtk+ 2.2.0", 1
    unless Gtk2->CHECK_VERSION (2, 2, 0);
  my @style = $widget->style_get ("focus-line-width", "focus-padding");
  is (@style, 2);
}

isa_ok ($widget->get_accessible, "Gtk2::Atk::Object");

ok (!$widget->child_focus ("down"));

$widget->child_notify ("expand");
$widget->freeze_child_notify;
$widget->thaw_child_notify;

$widget->set_child_visible (1);
is ($widget->get_child_visible, 1);

isa_ok ($widget->get_settings, "Gtk2::Settings");

$widget->set_size_request (100, 100);
is_deeply ([$widget->get_size_request], [100, 100]);

my $bitmap = Gtk2::Gdk::Bitmap->create_from_data ($win->window, "", 1, 1);

$win->realize;
$widget->shape_combine_mask ($bitmap, 5, 5);
$widget->shape_combine_mask (undef, 5, 5);

SKIP: {
	skip "stuff that's new in 2.2", 10
		unless Gtk2->CHECK_VERSION (2, 2, 0);

	isa_ok ($widget->get_clipboard, "Gtk2::Clipboard");
	isa_ok ($widget->get_display, "Gtk2::Gdk::Display");
	isa_ok ($widget->get_root_window, "Gtk2::Gdk::Window");
	isa_ok ($widget->get_screen, "Gtk2::Gdk::Screen");

	is ($widget->has_screen, 1);

	# not sure it's wise to enquire into what properties exist, but
	# let's assume there's at least 1
	{ my @pspecs = $widget->list_style_properties;
	  cmp_ok (scalar(@pspecs), '>', 0); }
	{ my @pspecs = Gtk2::Widget->list_style_properties;
	  cmp_ok (scalar(@pspecs), '>', 0); }

	is ($widget->find_style_property('no-such-style-property-of-this-name'),
	    undef,
	    "find_style_property() no such name, on object");
	is (Gtk2::Widget->find_style_property('no-such-style-property-of-this-name'),
	    undef,
	    "find_style_property() no such name, on class");
	is (Gtk2::Label->find_style_property('no-such-style-property-of-this-name'),
	    undef,
	    "find_style_property() no such name, on label class");

	# not sure it's wise to depend on properties exist, but at least
	# exercise the code on "interior-focus" which exists in 2.2 up
	$widget->find_style_property('interior-focus');
	Gtk2::Widget->find_style_property('interior-focus');
	Gtk2::Label->find_style_property('interior-focus');
}

SKIP: {
	skip "stuff that's new in 2.4", 3
		unless Gtk2->CHECK_VERSION (2, 4, 0);

	$widget->set_no_show_all (1);
	is ($widget->get_no_show_all, 1);

	$widget->queue_resize_no_redraw;

	ok (!$widget->can_activate_accel (23));

	my $label_one = Gtk2::Label->new ("_One");
	my $label_two = Gtk2::Label->new ("_Two");

	$widget->add_mnemonic_label ($label_one);
	$widget->add_mnemonic_label ($label_two);

	is_deeply ([$widget->list_mnemonic_labels], [$label_one, $label_two]);

	$widget->remove_mnemonic_label ($label_one);
	$widget->remove_mnemonic_label ($label_two);
}

SKIP: {
	skip "stuff that's new in 2.10", 0
		unless Gtk2->CHECK_VERSION (2, 10, 0);

	$widget->input_shape_combine_mask ($bitmap, 23, 42);
	$widget->input_shape_combine_mask (undef, 0, 0);

	$widget->is_composited;
}

SKIP: {
	skip "new 2.12 stuff", 8
		unless Gtk2->CHECK_VERSION (2, 12, 0);

	ok (defined $widget->keynav_failed ('tab-backward'));

	$widget->set_tooltip_window (undef);
	is ($widget->get_tooltip_window, undef);

	my $window = Gtk2::Window->new;
	$widget->set_tooltip_window ($window);
	is ($widget->get_tooltip_window, $window);

	$widget->trigger_tooltip_query;

	$widget->set_tooltip_text ('Bla');
	is ($widget->get_tooltip_text, 'Bla');
	$widget->set_tooltip_markup ('Bla');
	is ($widget->get_tooltip_markup, 'Bla');

	$widget->set_tooltip_text (undef);
	is ($widget->get_tooltip_text, undef);
	$widget->set_tooltip_markup (undef);
	is ($widget->get_tooltip_markup, undef);

	$widget->set_has_tooltip (FALSE);
	is ($widget->get_has_tooltip, FALSE);

	$widget->error_bell;

	$widget->modify_cursor (Gtk2::Gdk::Color->new (0x0000, 0x0000, 0x0000),
			        Gtk2::Gdk::Color->new (0xffff, 0xffff, 0xffff));
	$widget->modify_cursor (undef,undef);
}

SKIP: {
	skip 'new 2.14 stuff', 4
		unless Gtk2->CHECK_VERSION(2, 14, 0);

	my $widget = Gtk2::Label->new ('Bla');

	is ($widget->get_snapshot (), undef);

	my $window = Gtk2::Window->new ();
	$window->add ($widget);
	$window->show_all ();

	isa_ok ($widget->get_snapshot (), 'Gtk2::Gdk::Pixmap');
	isa_ok ($widget->get_snapshot (Gtk2::Gdk::Rectangle->new (0, 0, 1, 1)),
		'Gtk2::Gdk::Pixmap');

	isa_ok ($widget->get_window (), 'Gtk2::Gdk::Window');

	$window->signal_connect(
		delete_event => \&Gtk2::Widget::hide_on_delete);
	$window->signal_emit(
		delete_event => Gtk2::Gdk::Event->new ('key-press'));
}

SKIP: {
	skip 'new 2.18 stuff', 13
		unless Gtk2->CHECK_VERSION(2, 18, 0);
	my $widget = Gtk2::Label->new ('Bla');

	my $rect = Gtk2::Gdk::Rectangle->new (0, 0, 23, 42);
	$widget->set_allocation ($rect);
	my $new_rect = $widget->get_allocation;
	is ($new_rect->width, $rect->width);

	$widget->set_can_default (TRUE);
	ok ($widget->get_can_default);

	$widget->set_can_focus (TRUE);
	ok ($widget->get_can_focus);

	$widget->set_has_window (TRUE);
	ok ($widget->get_has_window);

	$widget->set_receives_default (TRUE);
	ok ($widget->get_receives_default);

	$widget->set_visible (TRUE);
	ok ($widget->get_visible);

	ok (defined $widget->get_app_paintable);
	ok (defined $widget->get_double_buffered);
	ok (defined $widget->get_sensitive);
	ok (defined $widget->get_state);
	ok (defined $widget->is_drawable);
	ok (defined $widget->is_sensitive);
	ok (defined $widget->is_toplevel);
}

SKIP: {
	skip 'new 2.20 stuff', 4
		unless Gtk2->CHECK_VERSION(2, 20, 0);

	my $widget = Gtk2::Label->new ('Bla');
	$widget->set_realized (FALSE);
	ok (!$widget->get_realized);
	$widget->set_mapped (FALSE);
	ok (!$widget->get_mapped);
	my $req = $widget->get_requisition;
	ok (defined $req->width && defined $req->height);
	ok (defined $widget->has_rc_style);

	my $window = Gtk2::Window->new;
	$window->add ($widget);
	$widget->realize;
	$widget->style_attach;
}

SKIP: {
	skip 'new 2.22 stuff', 0
		unless Gtk2->CHECK_VERSION(2, 22, 0);

	my $widget = Gtk2::Label->new ('Bla');
	my $event = Gtk2::Gdk::Event->new ('focus-change');
	$event->in (TRUE);
	$event->window ($widget->window);
	$widget->send_focus_change ($event);
}

__END__

Copyright (C) 2003-2006, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
