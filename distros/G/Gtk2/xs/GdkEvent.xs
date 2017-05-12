/*
 * Copyright (c) 2003-2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */

#include "gtk2perl.h"

/*

since the GdkEvent is a union, it behaves like a polymorphic structure.
gdk provides a couple of functions to return some common values regardless
of the type of event, but we need to provide access to pretty much all
of the members.

thus, i've created a bit of hierarchy within the GdkEvent itself.  specialized
event types inherit evreything else from Gtk2::Gdk::Event, but add their
own methods to provide access to the struct members.

by the way, we do everything as opaque types and methods instead of creating
a hash like gtk-perl in order to avoid the performance hit of always creating
a hash that maybe 20% of client code will ever actually use.

*/



static const char *
gdk_event_get_package (GType gtype,
                       GdkEvent * event)
{
	PERL_UNUSED_VAR (gtype);

	switch (event->type) {
	    case GDK_NOTHING:
	    case GDK_DELETE:
	    case GDK_DESTROY:
	    case GDK_MAP:
	    case GDK_UNMAP:
		return "Gtk2::Gdk::Event";
	    case GDK_EXPOSE:
#if GTK_CHECK_VERSION (2, 14, 0)
	    case GDK_DAMAGE:
#endif
		return "Gtk2::Gdk::Event::Expose";
	    case GDK_MOTION_NOTIFY:
		return "Gtk2::Gdk::Event::Motion";
	    case GDK_BUTTON_PRESS:
	    case GDK_2BUTTON_PRESS:
	    case GDK_3BUTTON_PRESS:
	    case GDK_BUTTON_RELEASE:
		return "Gtk2::Gdk::Event::Button";
	    case GDK_KEY_PRESS:
	    case GDK_KEY_RELEASE:
		return "Gtk2::Gdk::Event::Key";
	    case GDK_ENTER_NOTIFY:
	    case GDK_LEAVE_NOTIFY:
		return "Gtk2::Gdk::Event::Crossing";
	    case GDK_FOCUS_CHANGE:
		return "Gtk2::Gdk::Event::Focus";
	    case GDK_CONFIGURE:
		return "Gtk2::Gdk::Event::Configure";
	    case GDK_PROPERTY_NOTIFY:
		return "Gtk2::Gdk::Event::Property";
	    case GDK_SELECTION_CLEAR:
	    case GDK_SELECTION_REQUEST:
	    case GDK_SELECTION_NOTIFY:
		return "Gtk2::Gdk::Event::Selection";
	    case GDK_PROXIMITY_IN:
	    case GDK_PROXIMITY_OUT:
		return "Gtk2::Gdk::Event::Proximity";
	    case GDK_DRAG_ENTER:
	    case GDK_DRAG_LEAVE:
	    case GDK_DRAG_MOTION:
	    case GDK_DRAG_STATUS:
	    case GDK_DROP_START:
	    case GDK_DROP_FINISHED:
		return "Gtk2::Gdk::Event::DND";
	    case GDK_CLIENT_EVENT:
		return "Gtk2::Gdk::Event::Client";
	    case GDK_VISIBILITY_NOTIFY:
		return "Gtk2::Gdk::Event::Visibility";
	    case GDK_NO_EXPOSE:
		return "Gtk2::Gdk::Event::NoExpose";
	    case GDK_SCROLL:
		return "Gtk2::Gdk::Event::Scroll";
	    case GDK_WINDOW_STATE:
		return "Gtk2::Gdk::Event::WindowState";
	    case GDK_SETTING:
		return "Gtk2::Gdk::Event::Setting";
#if GTK_CHECK_VERSION (2, 6, 0)
	    case GDK_OWNER_CHANGE:
		return "Gtk2::Gdk::Event::OwnerChange";
#endif
#if GTK_CHECK_VERSION (2, 8, 0)
	    case GDK_GRAB_BROKEN:
		return "Gtk2::Gdk::Event::GrabBroken";
#endif
	    default:
		{
		GEnumClass * class = g_type_class_ref (GDK_TYPE_EVENT_TYPE);
		GEnumValue * value = g_enum_get_value (class, event->type);
		if (value)
			warn ("Unhandled event type %s (%d) in event->type",
			      value->value_name, event->type);
		else
			warn ("Unknown value %d in event->type", event->type);
		g_type_class_unref (class);
		}
		return "Gtk2::Gdk::Event"; /* limp along */
	}
}

static void
gtk2perl_gdk_event_set_state (GdkEvent * event,
                              GdkModifierType newstate)
{
	if (event) {
		switch (event->type) {
		    case GDK_MOTION_NOTIFY:
			event->motion.state = newstate;
			break;
		    case GDK_BUTTON_PRESS:
		    case GDK_2BUTTON_PRESS:
		    case GDK_3BUTTON_PRESS:
		    case GDK_BUTTON_RELEASE:
			event->button.state = newstate;
			break;
		    case GDK_SCROLL:
			event->scroll.state = newstate;
			break;
		    case GDK_KEY_PRESS:
		    case GDK_KEY_RELEASE:
			event->key.state = newstate;
			break;
		    case GDK_ENTER_NOTIFY:
		    case GDK_LEAVE_NOTIFY:
			event->crossing.state = newstate;
			break;
		    case GDK_PROPERTY_NOTIFY:
			event->property.state = newstate;
			break;
		    case GDK_VISIBILITY_NOTIFY:
			/* visibility state is something else. */
		    case GDK_CLIENT_EVENT:
		    case GDK_NO_EXPOSE:
		    case GDK_CONFIGURE:
		    case GDK_FOCUS_CHANGE:
		    case GDK_SELECTION_CLEAR:
		    case GDK_SELECTION_REQUEST:
		    case GDK_SELECTION_NOTIFY:
		    case GDK_PROXIMITY_IN:
		    case GDK_PROXIMITY_OUT:
		    case GDK_DRAG_ENTER:
		    case GDK_DRAG_LEAVE:
		    case GDK_DRAG_MOTION:
		    case GDK_DRAG_STATUS:
		    case GDK_DROP_START:
		    case GDK_DROP_FINISHED:
		    case GDK_NOTHING:
		    case GDK_DELETE:
		    case GDK_DESTROY:
		    case GDK_EXPOSE:
		    case GDK_MAP:
		    case GDK_UNMAP:
		    case GDK_WINDOW_STATE:
		    case GDK_SETTING:
#if GTK_CHECK_VERSION (2, 6, 0)
		    case GDK_OWNER_CHANGE:
#endif
#if GTK_CHECK_VERSION (2, 8, 0)
		    case GDK_GRAB_BROKEN:
#endif
#if GTK_CHECK_VERSION (2, 14, 0)
		    case GDK_DAMAGE:
#endif
			/* no state field */
			break;
		}
	}
}

static void
gtk2perl_gdk_event_set_time (GdkEvent * event,
                             guint32 newtime)
{
	if (event) {
		switch (event->type) {
		     case GDK_MOTION_NOTIFY:
			event->motion.time = newtime;
			break;
		     case GDK_BUTTON_PRESS:
		     case GDK_2BUTTON_PRESS:
		     case GDK_3BUTTON_PRESS:
		     case GDK_BUTTON_RELEASE:
			event->button.time = newtime;
			break;
		     case GDK_SCROLL:
			event->scroll.time = newtime;
			break;
		     case GDK_KEY_PRESS:
		     case GDK_KEY_RELEASE:
			event->key.time = newtime;
			break;
		     case GDK_ENTER_NOTIFY:
		     case GDK_LEAVE_NOTIFY:
			event->crossing.time = newtime;
			break;
		     case GDK_PROPERTY_NOTIFY:
			event->property.time = newtime;
			break;
		     case GDK_SELECTION_CLEAR:
		     case GDK_SELECTION_REQUEST:
		     case GDK_SELECTION_NOTIFY:
			event->selection.time = newtime;
			break;
		     case GDK_PROXIMITY_IN:
		     case GDK_PROXIMITY_OUT:
			event->proximity.time = newtime;
			break;
		     case GDK_DRAG_ENTER:
		     case GDK_DRAG_LEAVE:
		     case GDK_DRAG_MOTION:
		     case GDK_DRAG_STATUS:
		     case GDK_DROP_START:
		     case GDK_DROP_FINISHED:
			event->dnd.time = newtime;
			break;
#if GTK_CHECK_VERSION (2, 6, 0)
		     case GDK_OWNER_CHANGE:
			event->owner_change.time = newtime;
#endif
		     case GDK_CLIENT_EVENT:
		     case GDK_VISIBILITY_NOTIFY:
		     case GDK_NO_EXPOSE:
		     case GDK_CONFIGURE:
		     case GDK_FOCUS_CHANGE:
		     case GDK_NOTHING:
		     case GDK_DELETE:
		     case GDK_DESTROY:
		     case GDK_EXPOSE:
		     case GDK_MAP:
		     case GDK_UNMAP:
		     case GDK_WINDOW_STATE:
		     case GDK_SETTING:
#if GTK_CHECK_VERSION (2, 8, 0)
		     case GDK_GRAB_BROKEN:
#endif
#if GTK_CHECK_VERSION (2, 14, 0)
		    case GDK_DAMAGE:
#endif
			/* no time */
			break;
		}
	}
}

/* initialized in the boot section. */
static GPerlBoxedWrapperClass   gdk_event_wrapper_class;
static GPerlBoxedWrapperClass * default_wrapper_class;

static SV *
gdk_event_wrap (GType gtype,
                const char * package,
                GdkEvent * event,
		gboolean own)
{
	HV * stash;
	SV * sv;

	sv = default_wrapper_class->wrap (gtype, package, event, own);

	/* we don't really care about the registered package, override it. */
	package = gdk_event_get_package (gtype, event);
	stash = gv_stashpv (package, TRUE);
	return sv_bless (sv, stash);
}

static GdkEvent *
gdk_event_unwrap (GType gtype, const char * package, SV * sv)
{
	GdkEvent * event = default_wrapper_class->unwrap (gtype, package, sv);

	/* we don't really care about the registered package, override it. */
	package = gdk_event_get_package (gtype, event);

	if (!sv_derived_from (sv, package))
		croak ("%s is not of type %s",
		       gperl_format_variable_for_output (sv),
		       package);

	return event;
}

#if !GTK_CHECK_VERSION (2, 2, 0)
# define gdk_event_new	gtk2perl_gdk_event_new
static GdkEvent *
gtk2perl_gdk_event_new (GdkEventType type)
{
	GdkEvent ev;
	memset (&ev, 0, sizeof (GdkEvent));
	ev.any.type = type;
	return gdk_event_copy (&ev);
}
#endif

static void
gtk2perl_event_func (GdkEvent *event, gpointer data)
{
	gperl_callback_invoke ((GPerlCallback *) data, NULL, event);
}

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk	PREFIX = gdk_

 ## gboolean gdk_events_pending (void)
gboolean
gdk_events_pending (class)
    C_ARGS:
	/*void*/

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event	PREFIX = gdk_event_

=head1 EVENT TYPES

=over

=item * L<Gtk2::Gdk::Event::Button>

=item * L<Gtk2::Gdk::Event::Client>

=item * L<Gtk2::Gdk::Event::Configure>

=item * L<Gtk2::Gdk::Event::Crossing>

=item * L<Gtk2::Gdk::Event::DND>

=item * L<Gtk2::Gdk::Event::Expose>

=item * L<Gtk2::Gdk::Event::Focus>

=item * L<Gtk2::Gdk::Event::Key>

=item * L<Gtk2::Gdk::Event::Motion>

=item * L<Gtk2::Gdk::Event::NoExpose>

=item * L<Gtk2::Gdk::Event::Property>

=item * L<Gtk2::Gdk::Event::Proximity>

=item * L<Gtk2::Gdk::Event::Scroll>

=item * L<Gtk2::Gdk::Event::Selection>

=item * L<Gtk2::Gdk::Event::Setting>

=item * L<Gtk2::Gdk::Event::Visibility>

=item * L<Gtk2::Gdk::Event::WindowState>

=item * L<Gtk2::Gdk::Event::OwnerChange> (since gtk+ 2.6)

=item * L<Gtk2::Gdk::Event::GrabBroken> (since gtk+ 2.8)

=back

=cut

=for enum GdkEventType
=cut

BOOT:
	/* GdkEvent is a polymorphic structure, whose actual package
	 * depends on the type member's value.  instead of trying to make
	 * a perl developer know about this, we'll bless it into the proper
	 * subclass by overriding the default wrapper behavior.
	 *
	 * note that we expressly wish to keep the GdkEvent as an opaque
	 * type in gtk2-perl for efficiency; converting an event to a
	 * hash is an expensive operation that is usually wasted (based on
	 * experience with gtk-perl).
	 */
	default_wrapper_class = gperl_default_boxed_wrapper_class ();
	gdk_event_wrapper_class = * default_wrapper_class;
	gdk_event_wrapper_class.wrap = (GPerlBoxedWrapFunc)gdk_event_wrap;
	gdk_event_wrapper_class.unwrap = (GPerlBoxedUnwrapFunc)gdk_event_unwrap;
	gperl_register_boxed (GDK_TYPE_EVENT, "Gtk2::Gdk::Event",
	                      &gdk_event_wrapper_class);

 ## GdkEvent* gdk_event_get (void)
 ## GdkEvent* gdk_event_peek (void)
## caller must free
GdkEvent_own_ornull*
gdk_event_get (class)
    ALIAS:
	peek = 1
    C_ARGS:
	/*void*/
    CLEANUP:
	PERL_UNUSED_VAR (ix);

 ## GdkEvent* gdk_event_get_graphics_expose (GdkWindow *window)
GdkEvent_own_ornull*
gdk_event_get_graphics_expose (class, window)
	GdkWindow *window
    C_ARGS:
	window

 ## void gdk_event_put (GdkEvent *event)
## call as Gtk2::Gdk::Event->put ($event)
void
gdk_event_put (class, event)
	GdkEvent *event
    C_ARGS:
	event

 # this didn't actually exist until 2.2.0, when there were some private
 # things added in Gdk; we provide a custom one on 2.0.x, because we're
 # nice guys.
 ## GdkEvent* gdk_event_new (GdkEventType type)
## caller must free
GdkEvent_own*
gdk_event_new (class, type)
	GdkEventType type
    C_ARGS:
	type

 ## GdkEvent* gdk_event_copy (GdkEvent *event)
GdkEvent_own*
gdk_event_copy (event)
	GdkEvent *event

 # automatic
 ## void gdk_event_free (GdkEvent *event)

 ## guint32 gdk_event_get_time (GdkEvent *event)
=for apidoc Gtk2::Gdk::Event::set_time
=for signature $event->set_time ($newtime)
=for arg ... (hide)
=for arg newtime (integer) timestamp
=cut

# we'll doc this one below with get_time
=for apidoc Gtk2::Gdk::Event::time __hide__
=cut

=for apidoc
=for signature $timestamp = $event->get_time
=for signature $timestamp = $event->time
=for arg ... (hide)
Get I<$event>'s time.  If that event type doesn't have a time, or if
I<$event> is undef, returns GDK_CURRENT_TIME, which is 0.
=cut
guint
gdk_event_get_time (event, ...)
	GdkEvent_ornull *event
    ALIAS:
	Gtk2::Gdk::Event::time = 1
	Gtk2::Gdk::Event::set_time = 2
    CODE:
	if (ix == 0 && items != 1)
		croak ("Usage:  Gtk2::Gdk::Event::get_time (event)");
	if (ix == 2 && items != 2)
		croak ("Usage:  Gtk2::Gdk::Event::set_time (event, newtime)");
	RETVAL = gdk_event_get_time (event);
	if (items == 2 || ix == 2) {
		/* set */
		gtk2perl_gdk_event_set_time (event, SvIV (ST (1)));
	}
    OUTPUT:
	RETVAL

 ## gboolean gdk_event_get_state (GdkEvent *event, GdkModifierType *state)
=for apidoc Gtk2::Gdk::Event::set_state
=for signature $event->set_state ($newstate)
=for arg ... (hide)
=for arg newstate (GdkModifierType)
=cut

# we'll doc this one below with get_state
=for apidoc Gtk2::Gdk::Event::state __hide__
=cut

=for apidoc
=for signature $modifiertype = $event->get_state
=for signature $modifiertype = $event->state
=for arg ... (hide)
Get I<$event>'s state.  Croaks if that event type doesn't have a state.
=cut
GdkModifierType
gdk_event_get_state (event, ...)
	GdkEvent *event
    ALIAS:
	Gtk2::Gdk::Event::state = 1
	Gtk2::Gdk::Event::set_state = 2
    CODE:
	if (ix == 0 && items != 1)
		croak ("Usage:  Gtk2::Gdk::Event::get_state (event)");
	if (ix == 2 && items != 2)
		croak ("Usage:  Gtk2::Gdk::Event::set_state (event, newstate)");
	if (items == 2 || ix == 2) {
		/* set; return old value. */
		if (!gdk_event_get_state (event, &RETVAL)) {
			/* Use pass_unknown to prevent getting the rather
			 * unhelpful "invalid enum value" exception here for
			 * events added in newer gdks than that for which we
			 * were built.  If we're going to throw an exception,
			 * it should at least be somewhat meaningful. */
			SV * s = gperl_convert_back_enum_pass_unknown
					(GDK_TYPE_EVENT_TYPE, event->type);
			croak ("events of type %s have no state member",
			       SvPV_nolen (s));
		}
		gtk2perl_gdk_event_set_state (event,
		                              SvGdkModifierType (ST (1)));
	} else {
		/* just get */
		if (!gdk_event_get_state (event, &RETVAL))
			XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

=for apidoc Gtk2::Gdk::Event::get_coords
=for signature ($x, $y) = $event->get_coords
=cut

=for apidoc Gtk2::Gdk::Event::coords
=for signature ($x, $y) = $event->coords
=cut

 ## gboolean gdk_event_get_coords (GdkEvent *event, gdouble *x_win, gdouble *y_win)
void
gdk_event_get_coords (event)
	GdkEvent *event
    ALIAS:
	Gtk2::Gdk::Event::coords = 1
    PREINIT:
	gdouble x;
	gdouble y;
    PPCODE:
	if (!gdk_event_get_coords (event, &x, &y))
		XSRETURN_EMPTY;
	PERL_UNUSED_VAR (ix);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVnv (x)));
	PUSHs (sv_2mortal (newSVnv (y)));

=for apidoc Gtk2::Gdk::Event::get_root_coords
=for signature ($x_root, $y_root) = $event->get_root_coords
=cut

=for apidoc Gtk2::Gdk::Event::root_coords
=for signature ($x_root, $y_root) = $event->root_coords
=cut

=for apidoc Gtk2::Gdk::Event::x_root
=for signature integer = $event->x_root
=cut

=for apidoc Gtk2::Gdk::Event::y_root
=for signature integer = $event->y_root
=cut

 ## gboolean gdk_event_get_root_coords (GdkEvent *event, gdouble *x_root, gdouble *y_root)
void
gdk_event_get_root_coords (event)
	GdkEvent *event
    ALIAS:
	Gtk2::Gdk::Event::root_coords = 1
	Gtk2::Gdk::Event::x_root = 2
	Gtk2::Gdk::Event::y_root = 3
    PREINIT:
	gdouble x_root;
	gdouble y_root;
    PPCODE:
	if (!gdk_event_get_root_coords (event, &x_root, &y_root))
		XSRETURN_EMPTY;
	switch (ix) {
		case 2: /* x */
			PUSHs (sv_2mortal (newSVnv (x_root)));
			break;
		case 3: /* y */
			PUSHs (sv_2mortal (newSVnv (y_root)));
			break;
		default:
			EXTEND (SP, 2);
			PUSHs (sv_2mortal (newSVnv (x_root)));
			PUSHs (sv_2mortal (newSVnv (y_root)));
	}


 ## gboolean gdk_event_get_axis (GdkEvent *event, GdkAxisUse axis_use, gdouble *value)
gdouble
gdk_event_get_axis (event, axis_use)
	GdkEvent *event
	GdkAxisUse axis_use
    ALIAS:
	Gtk2::Gdk::Event::axis = 1
    CODE:
	PERL_UNUSED_VAR (ix);
	if (!gdk_event_get_axis (event, axis_use, &RETVAL))
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

 ## void gdk_event_handler_set (GdkEventFunc func, gpointer data, GDestroyNotify notify)
=for apidoc
=for arg func (subroutine) function to get called for each event.
Set the function that handles all events from GDK.  GTK+ uses this to
dispatch events, and as such this is rarely of use to applications,
unless you are implementing completely custom event dispatching (unlikely)
or preprocess events somehow and then pass them on to
C<Gtk2::main_do_event>.  As a special case, if I<func> is undef,
we "reset" the handler by passing the actual C function gtk_main_do_event
to GDK, to bypass the Perl marshaling (and take things back up to full
speed).
=cut
void
gdk_event_handler_set (class, func, data=NULL)
	SV * func
	SV * data
    PREINIT:
	GPerlCallback *callback;
	GType params[1];
    CODE:
    	params[0] = GDK_TYPE_EVENT;
	if (gperl_sv_is_defined (func)) {
		callback = gperl_callback_new (func, data,
		                               G_N_ELEMENTS (params),
		                               params, 0);
		gdk_event_handler_set (gtk2perl_event_func,
		                       callback,
		                       (GDestroyNotify) gperl_callback_destroy);
	} else {
		/* reset to gtk+'s event handler. */
		gdk_event_handler_set ((GdkEventFunc) gtk_main_do_event,
				       NULL, NULL);
	}

#if GTK_CHECK_VERSION (2,2,0)

void
gdk_event_set_screen (event, screen)
	GdkEvent * event
	GdkScreen * screen

GdkScreen *
gdk_event_get_screen (event)
	GdkEvent * event

#endif /* have GdkScreen */

 ## since we're overriding the package names, Glib::Boxed::DESTROY won't
 ## be able to find the right destructor, because these new names don't
 ## correspond to GTypes, and Glib::Boxed::DESTROY tries to find the GType
 ## from the package into which the SV is blessed.  we'll have to explicitly
 ## tell perl what destructor to use.
void
DESTROY (sv)
	SV * sv
    ALIAS:
	Gtk2::Gdk::Event::Expose::DESTROY      =  1
	Gtk2::Gdk::Event::NoExpose::DESTROY    =  2
	Gtk2::Gdk::Event::Visibility::DESTROY  =  3
	Gtk2::Gdk::Event::Motion::DESTROY      =  4
	Gtk2::Gdk::Event::Button::DESTROY      =  5
	Gtk2::Gdk::Event::Scroll::DESTROY      =  6
	Gtk2::Gdk::Event::Key::DESTROY         =  7
	Gtk2::Gdk::Event::Crossing::DESTROY    =  8
	Gtk2::Gdk::Event::Focus::DESTROY       =  9
	Gtk2::Gdk::Event::Configure::DESTROY   = 10
	Gtk2::Gdk::Event::Property::DESTROY    = 11
	Gtk2::Gdk::Event::Selection::DESTROY   = 12
	Gtk2::Gdk::Event::Proximity::DESTROY   = 13
	Gtk2::Gdk::Event::Client::DESTROY      = 14
	Gtk2::Gdk::Event::Setting::DESTROY     = 15
	Gtk2::Gdk::Event::WindowState::DESTROY = 16
	Gtk2::Gdk::Event::DND::DESTROY         = 17
	Gtk2::Gdk::Event::OwnerChange::DESTROY = 18
	Gtk2::Gdk::Event::GrabBroken::DESTROY  = 19
    CODE:
	PERL_UNUSED_VAR (ix);
	default_wrapper_class->destroy (sv);


## Event types.
##   Nothing: No event occurred.
##   Delete: A window delete event was sent by the window manager.
##	     The specified window should be deleted.
##   Destroy: A window has been destroyed.
##   Expose: Part of a window has been uncovered.
##   NoExpose: Same as expose, but no expose event was generated.
##   VisibilityNotify: A window has become fully/partially/not obscured.
##   MotionNotify: The mouse has moved.
##   ButtonPress: A mouse button was pressed.
##   ButtonRelease: A mouse button was release.
##   KeyPress: A key was pressed.
##   KeyRelease: A key was released.
##   EnterNotify: A window was entered.
##   LeaveNotify: A window was exited.
##   FocusChange: The focus window has changed. (The focus window gets
##		  keyboard events).
##   Resize: A window has been resized.
##   Map: A window has been mapped. (It is now visible on the screen).
##   Unmap: A window has been unmapped. (It is no longer visible on
##	    the screen).
##   Scroll: A mouse wheel was scrolled either up or down.
##   OwnerChange: The owner of a clipboard/selection changed.


 # struct _GdkEventAny
 # {
 #   GdkEventType type;
 #   GdkWindow *window;
 #   gint8 send_event;
 # };

GdkEventType
type (event)
	GdkEvent * event
    CODE:
	RETVAL = event->any.type;
    OUTPUT:
	RETVAL

GdkWindow_ornull *
window (GdkEvent * event, GdkWindow_ornull * newvalue=NULL)
    CODE:
	RETVAL = event->any.window;
	if (RETVAL) g_object_ref (event->any.window);

	if (items == 2 && newvalue != event->any.window)
	{
		if (event->any.window)
			g_object_unref (event->any.window);
		if (newvalue)
			g_object_ref (newvalue);
		event->any.window = newvalue;
	}
    OUTPUT:
	RETVAL
    CLEANUP:
	if (RETVAL) g_object_unref (RETVAL);

gint8
send_event (GdkEvent * event, gint8 newvalue=0)
    CODE:
	RETVAL = event->any.send_event;
	if (items == 2)
		event->any.send_event = newvalue;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Expose

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Expose

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Expose", "Gtk2::Gdk::Event");

 #struct _GdkEventExpose
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #  GdkRectangle area;
 #  GdkRegion *region;
 #  gint count; /* If non-zero, how many more events follow. */
 #};

GdkRectangle*
area (GdkEvent * eventexpose, GdkRectangle * newvalue=NULL)
    CODE:
	RETVAL = &(eventexpose->expose.area);
	if (items == 2)
	{
		eventexpose->expose.area.x = newvalue->x;
		eventexpose->expose.area.y = newvalue->y;
		eventexpose->expose.area.width = newvalue->width;
		eventexpose->expose.area.height = newvalue->height;
	}
    OUTPUT:
	RETVAL

GdkRegion_own_ornull *
region (GdkEvent * eventexpose, GdkRegion_ornull * newvalue=NULL)
    CODE:
	RETVAL = NULL;
	if (eventexpose->expose.region)
		RETVAL = gdk_region_copy (eventexpose->expose.region);
	if (items == 2 && newvalue != eventexpose->expose.region)
	{
		if (eventexpose->expose.region)
			gdk_region_destroy (eventexpose->expose.region);
		if (newvalue)
			eventexpose->expose.region = gdk_region_copy (newvalue);
		else
			eventexpose->expose.region = NULL;
	}
    OUTPUT:
	RETVAL

gint
count (GdkEvent * eventexpose, guint newvalue=0)
    CODE:
	RETVAL = eventexpose->expose.count;
	if (items == 2)
		eventexpose->expose.count = newvalue;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::NoExpose

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::NoExpose

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::NoExpose", "Gtk2::Gdk::Event");

 #struct _GdkEventNoExpose
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #};

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Visibility

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Visibility

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Visibility", "Gtk2::Gdk::Event");

 #struct _GdkEventVisibility
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #  GdkVisibilityState state;
 #};

# different return type, override Gtk2::Gdk::Event::state
GdkVisibilityState
state (GdkEvent * eventvisibility, GdkVisibilityState newvalue=0)
    CODE:
	RETVAL = eventvisibility->visibility.state;
	if (items == 2)
		eventvisibility->visibility.state = newvalue;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Motion

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Motion

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Motion", "Gtk2::Gdk::Event");

 #struct _GdkEventMotion
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #//  guint32 time;  <- gdk_event_get_time
 #  gdouble x;
 #  gdouble y;
 #//  gdouble *axes; <- get_axes
 #//  guint state; <- get_state
 #  gint16 is_hint;
 #  GdkDevice *device;
 #//  gdouble x_root, y_root; <- get_root_coords
 #};

guint
is_hint (GdkEvent * eventmotion, guint newvalue=0)
    CODE:
	RETVAL = eventmotion->motion.is_hint;
	if (items == 2)
		eventmotion->motion.is_hint = newvalue;
    OUTPUT:
	RETVAL

GdkDevice_ornull *
device (GdkEvent * eventmotion, GdkDevice_ornull * newvalue=NULL)
    CODE:
	RETVAL = eventmotion->motion.device;
	if (items == 2)
		eventmotion->motion.device = newvalue;
    OUTPUT:
	RETVAL

gdouble
x (GdkEvent * event, gdouble newvalue=0.0)
    CODE:
	RETVAL = event->motion.x;
	if (items == 2)
		event->motion.x = newvalue;
    OUTPUT:
	RETVAL

gdouble
y (GdkEvent * event, gdouble newvalue=0.0)
    CODE:
	RETVAL = event->motion.y;
	if (items == 2)
		event->motion.y = newvalue;
    OUTPUT:
	RETVAL

#if GTK_CHECK_VERSION (2, 12, 0)

# void gdk_event_request_motions (GdkEventMotion *event);
void
request_motions (GdkEvent *event)
    CODE:
	gdk_event_request_motions ((GdkEventMotion *) event);

#endif

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Button

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Button

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Button", "Gtk2::Gdk::Event");

 #struct _GdkEventButton
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #//  guint32 time;  <- gdk_event_get_time
 #  gdouble x;
 #  gdouble y;
 #//  gdouble *axes; <- get_axes
 #//  guint state; <- get_state
 #  guint button;
 #  GdkDevice *device;
 #//  gdouble x_root, y_root; <- get_root_coords
 #};

guint
button (GdkEvent * eventbutton, guint newvalue=0)
    CODE:
	RETVAL = eventbutton->button.button;
	if (items == 2)
		eventbutton->button.button = newvalue;
    OUTPUT:
	RETVAL

GdkDevice_ornull *
device (GdkEvent * eventbutton, GdkDevice_ornull * newvalue=NULL)
    CODE:
	RETVAL = eventbutton->button.device;
	if (items == 2)
		eventbutton->button.device = newvalue;
    OUTPUT:
	RETVAL

gdouble
x (GdkEvent * event, gdouble newvalue=0.0)
    CODE:
	RETVAL = event->button.x;
	if (items == 2)
		event->button.x = newvalue;
    OUTPUT:
	RETVAL

gdouble
y (GdkEvent * event, gdouble newvalue=0.0)
    CODE:
	RETVAL = event->button.y;
	if (items == 2)
		event->button.y = newvalue;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Scroll

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Scroll

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Scroll", "Gtk2::Gdk::Event");

 #struct _GdkEventScroll
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #//  guint32 time;  <- gdk_event_get_time
 #  gdouble x;
 #  gdouble y;
 #//  guint state; <- get_state
 #  GdkScrollDirection direction;
 #  GdkDevice *device;
 #//  gdouble x_root, y_root; <- get_root_coords
 #};

GdkScrollDirection
direction (GdkEvent * eventscroll, GdkScrollDirection newvalue=0)
    CODE:
	RETVAL = eventscroll->scroll.direction;
	if (items == 2)
		eventscroll->scroll.direction = newvalue;
    OUTPUT:
	RETVAL

GdkDevice_ornull *
device (GdkEvent * eventscroll, GdkDevice_ornull * newvalue=NULL)
    CODE:
	RETVAL = eventscroll->scroll.device;
	if (items == 2)
		eventscroll->scroll.device = newvalue;
    OUTPUT:
	RETVAL

gdouble
x (GdkEvent * event, gdouble newvalue=0.0)
    CODE:
	RETVAL = event->scroll.x;
	if (items == 2)
		event->scroll.x = newvalue;
    OUTPUT:
	RETVAL

gdouble
y (GdkEvent * event, gdouble newvalue=0.0)
    CODE:
	RETVAL = event->scroll.y;
	if (items == 2)
		event->scroll.y = newvalue;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Key

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Key

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Key", "Gtk2::Gdk::Event");

 #struct _GdkEventKey
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #//  guint32 time;  <- gdk_event_get_time
 #//  guint state; <- get_state
 #  guint keyval;
 #//  gint length; 	deprecated
 #//  gchar *string; 	deprecated
 #  guint16 hardware_keycode;
 #  guint8 group;
 #};

guint
keyval (GdkEvent * eventkey, guint newvalue=0)
    CODE:
	RETVAL = eventkey->key.keyval;
	if (items == 2)
		eventkey->key.keyval = newvalue;
    OUTPUT:
	RETVAL

guint16
hardware_keycode (GdkEvent * eventkey, guint16 newvalue=0)
    CODE:
	RETVAL = eventkey->key.hardware_keycode;
	if (items == 2)
		eventkey->key.hardware_keycode = newvalue;
    OUTPUT:
	RETVAL

guint8
group (GdkEvent * eventkey, guint8 newvalue=0)
    CODE:
	RETVAL = eventkey->key.group;
	if (items == 2)
		eventkey->key.group = newvalue;
    OUTPUT:
	RETVAL


MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Crossing

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Crossing

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Crossing", "Gtk2::Gdk::Event");

 #struct _GdkEventCrossing
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #  GdkWindow *subwindow;
 #//  guint32 time;  <- gdk_event_get_time
 #  gdouble x;
 #  gdouble y;
 #//  gdouble x_root; <- get_root_coords
 #//  gdouble y_root; <- get_root_coords
 #  GdkCrossingMode mode;
 #  GdkNotifyType detail;
 #  gboolean focus;
 #//  guint state; <- get_state
 #};

GdkWindow_ornull *
subwindow (GdkEvent * event, GdkWindow_ornull * newvalue=NULL)
    CODE:
	RETVAL = event->crossing.subwindow;
	if (RETVAL) g_object_ref (RETVAL);

	if (items == 2 && newvalue != event->crossing.subwindow)
	{
		if (event->crossing.subwindow)
			g_object_unref (event->crossing.subwindow);
		if (newvalue)
			g_object_ref (newvalue);
		event->crossing.subwindow = newvalue;
	}
    OUTPUT:
	RETVAL
    CLEANUP:
	if (RETVAL) g_object_unref (RETVAL);

GdkCrossingMode
mode (GdkEvent * eventcrossing, GdkCrossingMode newvalue=0)
    CODE:
	RETVAL = eventcrossing->crossing.mode;
	if (items == 2)
		eventcrossing->crossing.mode = newvalue;
    OUTPUT:
	RETVAL

GdkNotifyType
detail (GdkEvent * eventcrossing, GdkNotifyType newvalue=0)
    CODE:
	RETVAL = eventcrossing->crossing.detail;
	if (items == 2)
		eventcrossing->crossing.detail = newvalue;
    OUTPUT:
	RETVAL

gboolean
focus (GdkEvent * eventcrossing, gboolean newvalue=0)
    CODE:
	RETVAL = eventcrossing->crossing.focus;
	if (items == 2)
		eventcrossing->crossing.focus = newvalue;
    OUTPUT:
	RETVAL

gdouble
x (GdkEvent * event, gdouble newvalue=0.0)
    CODE:
	RETVAL = event->crossing.x;
	if (items == 2)
		event->crossing.x = newvalue;
    OUTPUT:
	RETVAL

gdouble
y (GdkEvent * event, gdouble newvalue=0.0)
    CODE:
	RETVAL = event->crossing.y;
	if (items == 2)
		event->crossing.y = newvalue;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Focus

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Focus

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Focus", "Gtk2::Gdk::Event");

 #struct _GdkEventFocus
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #  gint16 in;
 #};

gint16
in (GdkEvent * eventfocus, gint16 newvalue=0)
    CODE:
	RETVAL = eventfocus->focus_change.in;
	if (items == 2)
		eventfocus->focus_change.in = newvalue;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Configure

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Configure

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Configure", "Gtk2::Gdk::Event");

 #struct _GdkEventConfigure
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #  gint x, y;
 #  gint width;
 #  gint height;
 #};

gint
width (GdkEvent * eventconfigure, gint newvalue=0)
    ALIAS:
	Gtk2::Gdk::Event::Configure::height = 1
    CODE:
	switch (ix) {
		case 0:
			RETVAL = eventconfigure->configure.width;
			break;
		case 1:
			RETVAL = eventconfigure->configure.height;
			break;
		default:
			RETVAL = 0;
			g_assert_not_reached ();
	}
	if (items == 2)
	{
		switch (ix) {
			case 0:
				eventconfigure->configure.width = newvalue;
				break;
			case 1:
				eventconfigure->configure.height = newvalue;
				break;
			default:
				g_assert_not_reached ();
		}
	}
    OUTPUT:
	RETVAL

gint
x (GdkEvent * event, gint newvalue=0)
    CODE:
	RETVAL = event->configure.x;
	if (items == 2)
		event->configure.x = newvalue;
    OUTPUT:
	RETVAL

gint
y (GdkEvent * event, gint newvalue=0)
    CODE:
	RETVAL = event->configure.y;
	if (items == 2)
		event->configure.y = newvalue;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Property

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Property

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Property", "Gtk2::Gdk::Event");

 #struct _GdkEventProperty
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #  GdkAtom atom;
 #//  guint32 time;  <- gdk_event_get_time
 #  guint state;
 #};

GdkAtom
atom (GdkEvent * eventproperty, GdkAtom newvalue=0)
    CODE:
	RETVAL = eventproperty->property.atom;
	if (items == 2)
		eventproperty->property.atom = newvalue;
    OUTPUT:
	RETVAL

guint
state (GdkEvent * eventproperty, guint newvalue=0)
    CODE:
	RETVAL = eventproperty->property.state;
	if (items == 2)
		eventproperty->property.state = newvalue;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Selection

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Selection

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Selection", "Gtk2::Gdk::Event");

 #struct _GdkEventSelection
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #  GdkAtom selection;
 #  GdkAtom target;
 #  GdkAtom property;
 #//  guint32 time;  <- gdk_event_get_time
 #  GdkNativeWindow requestor;
 #};

GdkAtom
selection (GdkEvent * eventselection, GdkAtom newvalue=0)
    CODE:
	RETVAL = eventselection->selection.selection;
	if (items == 2)
		eventselection->selection.selection = newvalue;
    OUTPUT:
	RETVAL

GdkAtom
target (GdkEvent * eventselection, GdkAtom newvalue=0)
    CODE:
	RETVAL = eventselection->selection.target;
	if (items == 2)
		eventselection->selection.target = newvalue;
    OUTPUT:
	RETVAL

GdkAtom
property (GdkEvent * eventselection, GdkAtom newvalue=0)
    CODE:
	RETVAL = eventselection->selection.property;
	if (items == 2)
		eventselection->selection.property = newvalue;
    OUTPUT:
	RETVAL

GdkNativeWindow
requestor (GdkEvent * eventselection, GdkNativeWindow newvalue=0)
    CODE:
	RETVAL = eventselection->selection.requestor;
	if (items == 2)
		eventselection->selection.requestor = newvalue;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Proximity

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Proximity

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Proximity", "Gtk2::Gdk::Event");

 #/* This event type will be used pretty rarely. It only is important
 #   for XInput aware programs that are drawing their own cursor */

 #struct _GdkEventProximity
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #//  guint32 time;  <- gdk_event_get_time
 #  GdkDevice *device;
 #};

GdkDevice_ornull *
device (GdkEvent * eventproximity, GdkDevice_ornull * newvalue=NULL)
    CODE:
	RETVAL = eventproximity->motion.device;
	if (items == 2)
		eventproximity->motion.device = newvalue;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Client

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Client

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Client", "Gtk2::Gdk::Event");

 #struct _GdkEventClient
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #  GdkAtom message_type;
 #  gushort data_format;
 #  union {
 #    char b[20];
 #    short s[10];
 #    long l[5];
 #  } data;
 #};

GdkAtom
message_type (GdkEvent * eventclient, GdkAtom newvalue=0)
    CODE:
	RETVAL = eventclient->client.message_type;
	if (items == 2)
		eventclient->client.message_type = newvalue;
    OUTPUT:
	RETVAL

=for apidoc

This should be set to either $Gtk2::Gdk::CHARS, $Gtk2::Gdk::SHORTS, or
$Gtk2::Gdk::LONGS.  See I<data> for a full explanation.

=cut
gushort
data_format (GdkEvent * eventclient, gushort newvalue=0)
    CODE:
	RETVAL = eventclient->client.data_format;
	if (items == 2)
		eventclient->client.data_format = newvalue;
    OUTPUT:
	RETVAL

=for apidoc

=for signature old_string = $eventclient->data (string)
=for signature old_list = $eventclient->data (list of ten shorts)
=for signature old_list = $eventclient->data (list of five longs)

Depending on the value of I<data_format>, I<data> takes one of three different
kinds of values:

  +-------------------+-----------------------+
  |    data_format    |         data          |
  +-------------------+-----------------------+
  | Gtk2::Gdk::CHARS  | a string of length 20 |
  | Gtk2::Gdk::SHORTS | a list of ten shorts  |
  | Gtk2::Gdk::LONGS  | a list of five longs  |
  +-------------------+-----------------------+

=cut
void
data (GdkEvent * eventclient, ...)
    PREINIT:
	int i, first_index = 1;
    PPCODE:
	switch (eventclient->client.data_format) {
		case 8: {
			if (items == first_index + 1) {
				char *data = SvPV_nolen (ST (first_index));
				char old[20];

				for (i = 0; i < 20; i++) {
					old[i] = eventclient->client.data.b[i];
					eventclient->client.data.b[i] = data[i];
				}

				XPUSHs (sv_2mortal (newSVpv (old, 20)));
			} else {
				XPUSHs (sv_2mortal (newSVpv (eventclient->client.data.b, 20)));
			}

			break;
		}
		case 16: {
			if (items == first_index + 10) {
				short old[10];

				for (i = first_index; i < items; i++) {
					old[i - first_index] = eventclient->client.data.s[i - first_index];
					eventclient->client.data.s[i - first_index] = (gint16) SvIV (ST (i));
				}

				for (i = 0; i < 10; i++)
					XPUSHs (sv_2mortal (newSViv (old[i])));
					
			} else {
				for (i = 0; i < 10; i++)
					XPUSHs (sv_2mortal (newSViv (eventclient->client.data.s[i])));
			}

			break;
		}
		case 32: {
			if (items == first_index + 5) {
				long old[5];

				for (i = first_index; i < items; i++) {
					old[i - first_index] = eventclient->client.data.l[i - first_index];
					eventclient->client.data.l[i - first_index] = SvIV (ST (i));
				}

				for (i = 0; i < 5; i++)
					XPUSHs (sv_2mortal (newSViv (old[i])));
					
			} else {
				for (i = 0; i < 5; i++)
					XPUSHs (sv_2mortal (newSViv (eventclient->client.data.l[i])));
			}

			break;
		}
		default:
			croak ("Illegal format value %d used; should be either 8, 16 or 32", 
			       eventclient->client.data_format);
	}

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::Setting

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::Setting

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::Setting", "Gtk2::Gdk::Event");

 #struct _GdkEventSetting
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #  GdkSettingAction action;
 #  char *name;
 #};

GdkSettingAction
action (GdkEvent * eventsetting, GdkSettingAction newvalue=0)
    CODE:
	RETVAL = eventsetting->setting.action;
	if (items == 2)
		eventsetting->setting.action = newvalue;
    OUTPUT:
	RETVAL

char_ornull *
name (GdkEvent * eventsetting, char_ornull * newvalue=NULL)
    CODE:
	RETVAL = eventsetting->setting.name;
	if (items == 2)
	{
		if (eventsetting->setting.name)
			g_free (eventsetting->setting.name);

		if (newvalue)
			eventsetting->setting.name = g_strdup (newvalue);
		else
			eventsetting->setting.name = NULL;
	}
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::WindowState

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::WindowState

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::WindowState", "Gtk2::Gdk::Event");

 #struct _GdkEventWindowState
 #{
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #  GdkWindowState changed_mask;
 #  GdkWindowState new_window_state;
 #};

GdkWindowState
changed_mask (GdkEvent * eventwindowstate, GdkWindowState newvalue=0)
    CODE:
	RETVAL = eventwindowstate->window_state.changed_mask;
	if (items == 2)
		eventwindowstate->window_state.changed_mask = newvalue;
    OUTPUT:
	RETVAL

GdkWindowState
new_window_state (GdkEvent * eventwindowstate, GdkWindowState newvalue=0)
    CODE:
	RETVAL = eventwindowstate->window_state.new_window_state;
	if (items == 2)
		eventwindowstate->window_state.new_window_state = newvalue;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::DND

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::DND

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::DND", "Gtk2::Gdk::Event");

 #/* Event types for DND */

 #struct _GdkEventDND {
 #//  GdkEventType type;  <- GdkEventAny
 #//  GdkWindow *window;  <- GdkEventAny
 #//  gint8 send_event;  <- GdkEventAny
 #  GdkDragContext *context;

 #//  guint32 time;  <- gdk_event_get_time
 #//  gshort x_root, y_root; <- get_root_coords
 #};

GdkDragContext_ornull *
context (GdkEvent * eventdnd, GdkDragContext_ornull * newvalue=NULL)
    CODE:
	RETVAL = eventdnd->dnd.context;
	if (RETVAL) g_object_ref (RETVAL);

	if (items == 2 && newvalue != eventdnd->dnd.context)
	{
		if (eventdnd->dnd.context)
			g_object_unref (eventdnd->dnd.context);
		if (newvalue)
			g_object_ref (newvalue);
		eventdnd->dnd.context = newvalue;
	}
    OUTPUT:
	RETVAL
    CLEANUP:
	if (RETVAL) g_object_unref (RETVAL);

#if GTK_CHECK_VERSION (2, 6, 0)

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::OwnerChange

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::OwnerChange

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::OwnerChange", "Gtk2::Gdk::Event");

# struct _GdkEventOwnerChange
# {
#   GdkEventType type;  <- GdkEventAny
#   GdkWindow *window;  <- GdkEventAny
#   gint8 send_event;  <- GdkEventAny
#   GdkNativeWindow owner;
#   GdkOwnerChange reason;
#   GdkAtom selection;
#   guint32 time;  <- gdk_event_get_time
#   guint32 selection_time;
# };

GdkNativeWindow
owner (GdkEvent * event, GdkNativeWindow newvalue=0)
    CODE:
	RETVAL = event->owner_change.owner;

	if (items == 2 && newvalue != RETVAL)
	{
		event->owner_change.owner = newvalue;
	}
    OUTPUT:
	RETVAL

GdkOwnerChange
reason (GdkEvent * event, GdkOwnerChange newvalue=0)
    CODE:
	RETVAL = event->owner_change.reason;

	if (items == 2 && newvalue != RETVAL)
	{
		event->owner_change.reason = newvalue;
	}
    OUTPUT:
	RETVAL

GdkAtom
selection (GdkEvent * event, GdkAtom newvalue=0)
    CODE:
	RETVAL = event->owner_change.selection;

	if (items == 2 && newvalue != RETVAL)
	{
		event->owner_change.selection = newvalue;
	}
    OUTPUT:
	RETVAL

guint32
selection_time (GdkEvent * event, guint32 newvalue=0)
    CODE:
	RETVAL = event->owner_change.selection_time;

	if (items == 2 && newvalue != RETVAL)
	{
		event->owner_change.selection_time = newvalue;
	}
    OUTPUT:
	RETVAL

#endif

# --------------------------------------------------------------------------- #

#if GTK_CHECK_VERSION (2, 8, 0)

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk::Event::GrabBroken

=for position post_hierarchy

=head1 HIERARCHY

  Gtk2::Gdk::Event
  +----Gtk2::Gdk::Event::GrabBroken

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Event::GrabBroken", "Gtk2::Gdk::Event");

gboolean
keyboard (GdkEvent * event, gboolean newvalue=0)
    CODE:
	RETVAL = event->grab_broken.keyboard;

	if (items == 2 && newvalue != RETVAL)
		event->grab_broken.keyboard = newvalue;
    OUTPUT:
	RETVAL

gboolean
implicit (GdkEvent * event, gboolean newvalue=0)
    CODE:
	RETVAL = event->grab_broken.implicit;

	if (items == 2 && newvalue != RETVAL)
		event->grab_broken.implicit = newvalue;
    OUTPUT:
	RETVAL

=for apidoc
When you set a window into a GrabBroken event make sure you keep a
reference to it for as long as that event object or any copies exist,
because the event doesn't add its own reference.
=cut
GdkWindow_ornull *
grab_window (GdkEvent * event, GdkWindow_ornull * newvalue=NULL)
    CODE:
	RETVAL = event->grab_broken.grab_window;

	/* GdkEventGrabBroken doesn't hold a ref on grab_window, so
	 * just plonk the new value in, unlike for any.window above.
         */
	if (items == 2 && newvalue != RETVAL)
		event->grab_broken.grab_window = newvalue;
    OUTPUT:
	RETVAL

#endif

# --------------------------------------------------------------------------- #

MODULE = Gtk2::Gdk::Event	PACKAGE = Gtk2::Gdk	PREFIX = gdk_

# these are of limited usefulness, as you must have compiled GTK+
# with debugging turned on.

void
gdk_set_show_events (class, show_events)
	gboolean show_events
    C_ARGS:
	show_events

gboolean
gdk_get_show_events (class)
    C_ARGS:
	/*void*/

 # FIXME needs a callback
 ## void gdk_add_client_message_filter (GdkAtom message_type, GdkFilterFunc func, gpointer data)
 ##void
 ##gdk_add_client_message_filter (message_type, func, data)
 ##	GdkAtom message_type
 ##	GdkFilterFunc func
 ##	gpointer data

 ## gboolean gdk_setting_get (const gchar *name, GValue *value)
SV *
gdk_setting_get (class, name)
	const gchar *name
    PREINIT:
	GValue value = {0,};
    CODE:
	g_value_init (&value, G_TYPE_INT);
	if (!gdk_setting_get (name, &value))
		XSRETURN_UNDEF;
	RETVAL = gperl_sv_from_value (&value);
	g_value_unset (&value);
    OUTPUT:
	RETVAL
