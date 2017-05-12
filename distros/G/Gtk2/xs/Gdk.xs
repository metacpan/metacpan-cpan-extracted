/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::Gdk	PACKAGE = Gtk2::Gdk	PREFIX = gdk_

##  void gdk_init (gint *argc, gchar ***argv) 
gboolean
gdk_init (class=NULL)
    ALIAS:
	Gtk2::Gdk::init_check = 1
    PREINIT:
	GPerlArgv *pargv;
    CODE:
	pargv = gperl_argv_new ();

	if (ix == 1) {
		RETVAL = gdk_init_check (&pargv->argc, &pargv->argv);
	} else {
		gdk_init (&pargv->argc, &pargv->argv);
		/* gdk_init() either succeeds or does not return. */
		RETVAL = TRUE;
	}

	gperl_argv_update (pargv);
	gperl_argv_free (pargv);
    OUTPUT:
	RETVAL

#if GTK_CHECK_VERSION(2,2,0)

##  void gdk_parse_args (gint *argc, gchar ***argv) 
void
gdk_parse_args (class=NULL)
    PREINIT:
	GPerlArgv *pargv;
    CODE:
	pargv = gperl_argv_new ();

	gdk_parse_args (&pargv->argc, &pargv->argv);

	gperl_argv_update (pargv);
	gperl_argv_free (pargv);

const gchar *
gdk_get_display_arg_name (class)
    C_ARGS:
	/* void */
	

#endif /* >= 2.2.0 */

### deprecated
	

##  gchar* gdk_set_locale (void) 
gchar*
gdk_set_locale (class)
    C_ARGS:
	/* void */
	

## allow NULL to remove the property
void
gdk_set_sm_client_id (class, sm_client_id=NULL)
	const gchar_ornull * sm_client_id
    C_ARGS:
	sm_client_id

#if GTK_CHECK_VERSION(2,2,0)

##  void gdk_notify_startup_complete (void) 
void
gdk_notify_startup_complete (class)
    C_ARGS:
	/* void */

#endif /* 2.2.0 */

#if GTK_CHECK_VERSION(2, 12, 0)

void gdk_notify_startup_complete_with_id (class, const gchar* startup_id)
    C_ARGS:
	startup_id

#endif

const char *
gdk_get_program_class (class)
    C_ARGS:
	/* void */

void
gdk_set_program_class (class, program_class)
	const char *program_class
    C_ARGS:
	program_class

##  gchar* gdk_get_display (void) 
gchar *
gdk_get_display (class)
    C_ARGS:
	/* void */
    CLEANUP:
	/* in versions later than 2.2.0, this string is malloc'd. */
	if (NULL == gtk_check_version (2, 2, 0))
		g_free (RETVAL);

##  void gdk_flush (void) 
void
gdk_flush (class)
    C_ARGS:
	/* void */
	

gint
screen_width (class)
    ALIAS:
	Gtk2::Gdk::screen_height = 1
	Gtk2::Gdk::screen_width_mm = 2
	Gtk2::Gdk::screen_height_mm = 3
    CODE:
	switch (ix) {
		case 0: RETVAL = gdk_screen_width (); break;
		case 1: RETVAL = gdk_screen_height (); break;
		case 2: RETVAL = gdk_screen_width_mm (); break;
		case 3: RETVAL = gdk_screen_height_mm (); break;
		default:
			RETVAL = 0;
			g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

##  GdkGrabStatus gdk_pointer_grab (GdkWindow *window, gboolean owner_events, GdkEventMask event_mask, GdkWindow *confine_to, GdkCursor *cursor, guint32 time_) 
GdkGrabStatus
gdk_pointer_grab (class, window, owner_events, event_mask, confine_to, cursor, time_)
	GdkWindow        * window
	gboolean           owner_events
	GdkEventMask       event_mask
	GdkWindow_ornull * confine_to
	GdkCursor_ornull * cursor
	guint32            time_
    C_ARGS:
	window, owner_events, event_mask, confine_to, cursor, time_

##  void gdk_pointer_ungrab (guint32 time_) 
void
gdk_pointer_ungrab (class, time_)
	guint32 time_
    C_ARGS:
	time_

##  gboolean gdk_pointer_is_grabbed (void) 
gboolean
gdk_pointer_is_grabbed (class)
    C_ARGS:
	/* void */

##  GdkGrabStatus gdk_keyboard_grab (GdkWindow *window, gboolean owner_events, guint32 time_) 
GdkGrabStatus
gdk_keyboard_grab (class, window, owner_events, time_)
	GdkWindow *window
	gboolean owner_events
	guint32 time_
    C_ARGS:
	window, owner_events, time_

##  void gdk_keyboard_ungrab (guint32 time_) 
void
gdk_keyboard_ungrab (class, time_)
	guint32 time_
    C_ARGS:
	time_

##  void gdk_beep (void) 
void
gdk_beep (class)
    C_ARGS:
	/* void */

### deprecated
##  gboolean gdk_get_use_xshm (void) 
##  void gdk_set_use_xshm (gboolean use_xshm) 


##  void gdk_error_trap_push (void) 
void
gdk_error_trap_push (class)
    C_ARGS:
	/* void */

##  gint gdk_error_trap_pop (void) 
gint
gdk_error_trap_pop (class)
    C_ARGS:
	/* void */

### deprecated in favor of Glib::IO::add_watch etc
##  gint gdk_input_add_full (gint source, GdkInputCondition condition, GdkInputFunction function, gpointer data, GdkDestroyNotify destroy) 
##  gint gdk_input_add (gint source, GdkInputCondition condition, GdkInputFunction function, gpointer data) 
##  void gdk_input_remove (gint tag) 

### applications should not set this.
##  void gdk_set_double_click_time (guint msec) 

MODULE = Gtk2::Gdk	PACKAGE = Gtk2::Gdk::Rectangle	PREFIX = gdk_rectangle_

##  gboolean gdk_rectangle_intersect (GdkRectangle *src1, GdkRectangle *src2, GdkRectangle *dest) 
GdkRectangle_copy *
gdk_rectangle_intersect (src1, src2)
	GdkRectangle *src1
	GdkRectangle *src2
    PREINIT:
	GdkRectangle dest;
    CODE:
	if (!gdk_rectangle_intersect (src1, src2, &dest))
		XSRETURN_UNDEF;
	RETVAL = &dest;
    OUTPUT:
	RETVAL

##  void gdk_rectangle_union (GdkRectangle *src1, GdkRectangle *src2, GdkRectangle *dest) 
GdkRectangle_copy *
gdk_rectangle_union (src1, src2)
	GdkRectangle *src1
	GdkRectangle *src2
    PREINIT:
	GdkRectangle dest;
    CODE:
	gdk_rectangle_union (src1, src2, &dest);
	RETVAL = &dest;
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk	PACKAGE = Gtk2::Gdk	PREFIX = gdk_

### not bound, in favor of native perl support for unicode and utf8.
##  gchar *gdk_wcstombs (const GdkWChar *src) 
##  gint gdk_mbstowcs (GdkWChar *dest, const gchar *src, gint dest_max) 

MODULE = Gtk2::Gdk	PACKAGE = Gtk2::Gdk::Event	PREFIX = gdk_event_

##  gboolean gdk_event_send_client_message (GdkEvent *event, GdkNativeWindow winid) 
gboolean
gdk_event_send_client_message (class, event, winid)
	GdkEvent *event
	GdkNativeWindow winid
    C_ARGS:
	event, winid

##  void gdk_event_send_clientmessage_toall (GdkEvent *event) 
void
gdk_event_send_clientmessage_toall (class, event)
	GdkEvent *event
    C_ARGS:
	event

#if GTK_CHECK_VERSION (2, 2, 0)

##  gboolean gdk_event_send_client_message_for_display (GdkDisplay *display, GdkEvent *event, GdkNativeWindow winid) 
gboolean
gdk_event_send_client_message_for_display (class, display, event, winid)
	GdkDisplay *display
	GdkEvent *event
	GdkNativeWindow winid
    C_ARGS:
	display, event, winid

#endif

MODULE = Gtk2::Gdk	PACKAGE = Gtk2::Gdk::Threads	PREFIX = gdk_threads_

###  void gdk_threads_enter (void) 
###  void gdk_threads_leave (void) 
###  void gdk_threads_init (void) 

void
gdk_threads_init (class)
    ALIAS:
	enter = 1
	leave = 2
    CODE:
	switch (ix) {
		case 0: gdk_threads_init (); break;
		case 1: gdk_threads_enter (); break;
		case 2: gdk_threads_leave (); break;
		default:
			g_assert_not_reached ();
	}
