# vim: set filetype=perl :
#
# $Id$
#

#########################
# GdkEvent Tests
# 	- rm
#########################

use Gtk2::TestHelper tests => 123;
use Data::Dumper;

# Expose #######################################################################

isa_ok (my $event = Gtk2::Gdk::Event->new ('expose'),
	'Gtk2::Gdk::Event::Expose', 'Gtk2::Gdk::Event->new expose');
isa_ok ($event->copy, 'Gtk2::Gdk::Event::Expose');

is ($event->type, 'expose');

$event->area (Gtk2::Gdk::Rectangle->new (0, 0, 100, 100));
my $rect = $event->area;
ok (eq_array ([$rect->x, $rect->y, $rect->width, $rect->height],
	      [0, 0, 100, 100]), '$expose_event->area');

$event->region (Gtk2::Gdk::Region->new);
isa_ok ($event->region, 'Gtk2::Gdk::Region', '$expose_event->region');
$event->region (undef);
is ($event->region, undef, '$expose_event->region');

$event->count (10);
is ($event->count, 10, '$expose_event->count');

# Visibility ###################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('visibility-notify'),
	'Gtk2::Gdk::Event::Visibility', 'Gtk2::Gdk::Event->new visibility');

$event->state ('partial');
is ($event->state, 'partial', '$visibility_event->state');

# Motion #######################################################################

my $window = Gtk2::Gdk::Window->new (undef, {
			width => 20,
			height => 20,
			wclass => "output",
			window_type => "toplevel"
		});

my $device = Gtk2::Gdk::Device -> get_core_pointer();

isa_ok ($event = Gtk2::Gdk::Event->new ('motion-notify'),
	'Gtk2::Gdk::Event::Motion', 'Gtk2::Gdk::Event->new motion');

$event->is_hint (2);
is ($event->is_hint, 2, '$motion_event->is_hint');

$event->device ($device);
is ($event->device, $device, '$motion_event->device');

$event->device (undef);
is ($event->device, undef, '$motion_event->device & undef');

$event->x (13);
is ($event->x, 13, '$motion_event->x');

$event->y (13);
is ($event->y, 13, '$motion_event->y');

SKIP: {
	skip "new 2.12 stuff", 0
		unless Gtk2->CHECK_VERSION (2, 12, 0);

	$event->device ($device);
	$event->window ($window);
	$event->request_motions;
}

# Button #######################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('button-press'),
	'Gtk2::Gdk::Event::Button', 'Gtk2::Gdk::Event->new button');

$event->button (2);
is ($event->button, 2, '$button_event->button');

$event->device ($device);
is ($event->device, $device, '$button_event->device');

$event->device (undef);
is ($event->device, undef, '$button_event->device & undef');

$event->x (13);
is ($event->x, 13, '$button_event->x');

$event->y (13);
is ($event->y, 13, '$button_event->y');

# Scroll #######################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('scroll'),
	'Gtk2::Gdk::Event::Scroll', 'Gtk2::Gdk::Event->new scroll');

$event->direction ('down');
is ($event->direction, 'down', '$scroll_event->direction');

$event->device ($device);
is ($event->device, $device, '$scroll_event->device');

$event->device (undef);
is ($event->device, undef, '$scroll_event->device & undef');

$event->x (13);
is ($event->x, 13, '$scroll_event->x');

$event->y (13);
is ($event->y, 13, '$scroll_event->y');

# Key ##########################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('key-press'),
	'Gtk2::Gdk::Event::Key', 'Gtk2::Gdk::Event->new key');

$event->keyval (44);
is ($event->keyval, 44, '$key_event->keyval');

$event->hardware_keycode (10);
is ($event->hardware_keycode, 10, '$key_event->hardware_keycode');

$event->group (11);
is ($event->group, 11, '$key_event->group');

# Crossing #####################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('enter-notify'),
	'Gtk2::Gdk::Event::Crossing', 'Gtk2::Gdk::Event->new crossing');

$event->subwindow ($window);
is ($event->subwindow, $window, '$crossing_event->window');

$event->subwindow (undef);
is ($event->subwindow, undef, '$crossing_event->window & undef');

$event->mode ('grab');
is ($event->mode, 'grab', '$crossing_event->mode');

$event->detail ('nonlinear');
is ($event->detail, 'nonlinear', '$crossing_event->detail');

$event->focus (1);
is ($event->focus, 1, '$crossing_event->focus');

# try out the base class stuff, crossing is good b/c it has most of the stuff

is ($event->time, 0, '$event->time');
is ($event->get_time, 0, '$event->time');

# special case for get_time()
is (Gtk2::Gdk::Event::get_time(undef), 0,
    "get_time with no event gets GDK_CURRENT_TIME, which is 0");

is_deeply (\@{ $event->state }, [], '$event->state');
is_deeply (\@{ $event->get_state }, [], '$event->state');

ok (eq_array ([$event->coords], [0, 0]), '$event->coords');
is ($event->x, 0, '$event->x');
is ($event->y, 0, '$event->y');

is_deeply ([$event->get_root_coords], [0, 0], '$event->get_root_coords');
is ($event->x_root, 0, '$event->x_root');
is ($event->y_root, 0, '$event->y_root');

SKIP: {
	skip "GdkScreen is new in 2.2", 1
		unless Gtk2->CHECK_VERSION (2, 2, 0);

	my $screen = Gtk2::Gdk::Screen->get_default;

	$event->set_screen ($screen);
	is ($event->get_screen, $screen, '$event->get_screen');
}

$event->window ($window);
is ($event->window, $window, '$event->window');

$event->window (undef);
is ($event->window, undef, '$event->window & undef');

$event->send_event (3);
is ($event->send_event, 3, '$event->send_event');

$event->x (13);
is ($event->x, 13, '$crossing_event->x');

$event->y (13);
is ($event->y, 13, '$crossing_event->y');

is ($event->axis ("x"), 13);
is ($event->get_axis ("y"), 13);

is_deeply ([$event->coords], [13, 13]);
is_deeply ([$event->get_coords], [13, 13]);

# a little stress-testing on the complicated parameter validation of
# get_state|set_state|state
eval { $event->set_state; };
like ($@, qr/Usage/, 'set_state with no args croaks');
eval { $event->get_state ('foo'); };
like ($@, qr/Usage/, 'get_state with an arg croaks');
eval { $event->state; };
is ($@, '', "state with no args doesn't croak");
eval { $event->state ('control-mask'); };
is ($@, '', "nor does state with an arg");

# similarly for get_time|set_time|time
eval { $event->set_time; };
like ($@, qr/Usage/, "set_time with no args croaks");
eval { $event->get_time ('foo'); };
like ($@, qr/Usage/, "get_time with an arg croaks");
eval { $event->time; };
is ($@, '', "time with no args does not croak");
eval { $event->time (time); };
is ($@, '', "nor does time with an arg");

Gtk2::Gdk::Event->put ($event);
is (Gtk2::Gdk->events_pending, 1);
isa_ok (Gtk2::Gdk::Event->get, "Gtk2::Gdk::Event");

Gtk2::Gdk::Event->put ($event);
is (Gtk2::Gdk->events_pending, 1);
isa_ok (Gtk2::Gdk::Event->peek, "Gtk2::Gdk::Event");

my $i_know_you = 0;

Gtk2::Gdk::Event -> handler_set(sub {
	return if $i_know_you++;

	my ($ev, $data) = @_;

	ok ((ref $ev eq 'Gtk2::Gdk::Event::Crossing' or
	     UNIVERSAL::isa ($ev, 'Gtk2::Gdk::Event')), '$ev of expected type');
	is ($data, 'bla', 'user data passed properly');

	# pass to gtk+ default handler
	Gtk2->main_do_event ($ev);
}, 'bla');

Gtk2::Gdk::Event->put ($event);
Gtk2->main_iteration while Gtk2->events_pending;

# reset
Gtk2::Gdk::Event -> handler_set (undef);

# FIXME: how to test?  seems to block.
# warn Gtk2::Gdk::Event->get_graphics_expose ($window);

Gtk2::Gdk -> set_show_events (1);
is (Gtk2::Gdk -> get_show_events, 1);

SKIP: {
  # this will return undef if the setting is not set on your window manager,
  # which is pretty much the case when you are not running under gnome.
  my $dct = Gtk2::Gdk->setting_get ("gtk-double-click-time");
  skip "setting gtk-double-click-time not set?", 1
    unless defined $dct;
  like (Gtk2::Gdk->setting_get ("gtk-double-click-time"), qr/^\d+$/);
}

# Focus ########################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('focus-change'),
	'Gtk2::Gdk::Event::Focus', 'Gtk2::Gdk::Event->new focus');

$event->in (10);
is ($event->in, 10, '$focus_event->in');

# Configure ####################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('configure'),
	'Gtk2::Gdk::Event::Configure', 'Gtk2::Gdk::Event->new configure');

$event->width (10);
is ($event->width, 10, '$configure_event->width');

$event->height (12);
is ($event->height, 12, '$configure_event->height');

$event->x (13);
is ($event->x, 13, '$configure_event->x');

$event->y (13);
is ($event->y, 13, '$configure_event->y');

# Property #####################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('property-notify'),
	'Gtk2::Gdk::Event::Property', 'Gtk2::Gdk::Event->new property');

$event->state (10);
is ($event->state, 10, '$property_event->state');

$event->atom (Gtk2::Gdk::Atom->new ('foo'));
isa_ok ($event->atom, 'Gtk2::Gdk::Atom', '$property_event->atom');

# Proximity ####################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('proximity-in'),
	'Gtk2::Gdk::Event::Proximity', 'Gtk2::Gdk::Event->new proximity');

$event->device ($device);
is ($event->device, $device, '$proximity_event->device');

$event->device (undef);
is ($event->device, undef, '$proximity_event->device & undef');

# Client #######################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('client-event'),
	'Gtk2::Gdk::Event::Client', 'Gtk2::Gdk::Event->new client');

$event->message_type (Gtk2::Gdk::Atom->new ('string'));
isa_ok ($event->message_type, 'Gtk2::Gdk::Atom', '$event->message_type');

$event->data_format (Gtk2::Gdk::CHARS);
is ($event->data_format, Gtk2::Gdk::CHARS, '$client_event->data_format');

$event->data ('01234567890123456789');
is ($event->data, '01234567890123456789', '$client_event->data');

$event->data_format (Gtk2::Gdk::SHORTS);
is ($event->data_format, Gtk2::Gdk::SHORTS, '$client_event->data_format');

$event->data (0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
is_deeply ([$event->data], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], '$client_event->data');

$event->data_format (Gtk2::Gdk::LONGS);
is ($event->data_format, Gtk2::Gdk::LONGS, '$client_event->data_format');

$event->data (0, 1, 2, 3, 4);
is_deeply ([$event->data], [0, 1, 2, 3, 4], '$client_event->data');

# Setting ######################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('setting'),
	'Gtk2::Gdk::Event::Setting', 'Gtk2::Gdk::Event->new setting');

$event->action ('new');
is ($event->action, 'new', '$setting_event->action');

$event->name ('a name');
is ($event->name, 'a name', '$setting_event->name');

$event->name (undef);
is ($event->name, undef, '$setting_event->name & undef');

# WindowState ##################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('window-state'),
	'Gtk2::Gdk::Event::WindowState', 'Gtk2::Gdk::Event->new windowstate');

$event->changed_mask ('maximized');
is_deeply (\@{ $event->changed_mask }, ['maximized'],
	   '$windowstate_event->changed_mask');

$event->new_window_state ('withdrawn');
is_deeply (\@{ $event->new_window_state }, ['withdrawn'],
	   '$windowstate_event->new_window_state');

# DND ##########################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('drag-enter'),
	'Gtk2::Gdk::Event::DND', 'Gtk2::Gdk::Event->new dnd');

$event->context (Gtk2::Gdk::DragContext->new);
isa_ok ($event->context, 'Gtk2::Gdk::DragContext', '$dnd_event->context');

$event->context (undef);
is ($event->context, undef, '$dnd_event->context & undef');

# put this back to keep the event destructor from barfing on a NULL pointer
$event->context (Gtk2::Gdk::DragContext->new);

# Selection ####################################################################

isa_ok ($event = Gtk2::Gdk::Event->new ('selection-clear'),
	'Gtk2::Gdk::Event::Selection', 'Gtk2::Gdk::Event->new selection');

$event->selection (Gtk2::Gdk::Atom->new ('foo'));
isa_ok ($event->selection, 'Gtk2::Gdk::Atom', '$selection_event->selection');
# try setting to undef once
$event->selection (undef);
is ($event->selection, undef, '$selection_event->selection');

$event->target (Gtk2::Gdk::Atom->new ('foo'));
isa_ok ($event->target, 'Gtk2::Gdk::Atom', '$selection_event->target');

$event->property (Gtk2::Gdk::Atom->new ('foo'));
isa_ok ($event->property, 'Gtk2::Gdk::Atom', '$selection_event->property');

SKIP: {
	skip "can't do x11 stuff on this platform", 1
		if $^O eq 'MSWin32';

	$event->requestor ($window->get_xid);
	is ($event->requestor, $window->get_xid, '$selection_event->requestor');
}

# OwnerChange ##################################################################

SKIP: {
	skip ("the owner-change event is new in 2.6", 5)
		unless (Gtk2->CHECK_VERSION (2, 6, 0));

	isa_ok ($event = Gtk2::Gdk::Event->new ("owner-change"),
		"Gtk2::Gdk::Event::OwnerChange");

	$event->owner (23);
	is ($event->owner, 23);

	$event->reason ("destroy");
	is ($event->reason, "destroy");

	$event->selection (Gtk2::Gdk::Atom->new ("bar"));
	isa_ok ($event->selection, "Gtk2::Gdk::Atom");

	$event->selection_time (42);
	is ($event->selection_time, 42);
}

# GrabBroken ##################################################################

SKIP: {
	skip ("the grab-broken event is new in 2.8", 5)
		unless (Gtk2->CHECK_VERSION (2, 8, 0));

	isa_ok ($event = Gtk2::Gdk::Event->new ("grab-broken"),
		"Gtk2::Gdk::Event::GrabBroken");

	$event->keyboard (TRUE);
	is ($event->keyboard, TRUE);

	$event->implicit (FALSE);
	is ($event->implicit, FALSE);

	$event->grab_window (undef);
	is ($event->grab_window, undef);

	my $window = Gtk2::Gdk::Window->new (undef, {window_type => "toplevel"});
	$event->grab_window ($window);
	is ($event->grab_window, $window);
}

# Damage ######################################################################

SKIP: {
	skip ("the damage event is new in 2.14", 2)
		unless (Gtk2->CHECK_VERSION (2, 14, 0));

	isa_ok (my $event = Gtk2::Gdk::Event->new ('damage'),
		'Gtk2::Gdk::Event::Expose');
	is ($event->type, 'damage');
}

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

