/* -*- mode: C; c-file-style: "bsd" -*- */

#include <X11/Xlib.h>
#include <X11/Xatom.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int error_handler(Display *display, XErrorEvent *error_event)
{
    return TRUE;
}

char *get_ior (Display *display)
{
    Atom ns_atom = XInternAtom(display, "GNOME_NAME_SERVER", FALSE);
    Atom ns_ior_atom = XInternAtom(display, "GNOME_NAME_SERVER_IOR", FALSE);

    Window ns_window;
    
    Atom ret_type;
    unsigned long ret_nitems, ret_bytes_after;
    unsigned char *ret_prop;
    int ret_fmt;
    
    if (XGetWindowProperty(display, DefaultRootWindow (display), ns_atom,
			   0, 1, False, XA_WINDOW,
			   &ret_type, &ret_fmt, &ret_nitems, &ret_bytes_after,
			   &ret_prop) != Success)
	return NULL;

    if (ret_type == XA_WINDOW && ret_prop != NULL) {
	ns_window = *(Window *)ret_prop;
	XFree (ret_prop);
    } else {
	return NULL;
    }

    if (XGetWindowProperty(display, ns_window, ns_ior_atom,
			   0, 9999, False, XA_STRING,
			   &ret_type, &ret_fmt, &ret_nitems, &ret_bytes_after,
			   &ret_prop) != Success)
	return NULL;
	
    if (ret_type == XA_STRING && ret_prop != NULL) {
	char *retval = strdup (ret_prop);
	XFree (ret_prop);
	return retval;
    } else {
	return NULL;
    }
}

char *get_cookie_from_func (SV *generate_func)
{
    char *result;
    int count;
 
    dSP;
    
    PUSHMARK(sp);
    count = perl_call_sv (generate_func, G_SCALAR);
    SPAGAIN;
    
    result = strdup (POPp);
    assert (result);
    
    PUTBACK;

    return result;
}

char *get_cookie (Display *display, Atom prop)
{
    Atom ret_type;
    unsigned long ret_nitems, ret_bytes_after;
    unsigned char *ret_prop;
    int ret_fmt;
    char *result = NULL;
    
    XGetWindowProperty(display, DefaultRootWindow (display), prop,
		       0, 9999, False, XA_STRING,
		       &ret_type, &ret_fmt, &ret_nitems, &ret_bytes_after,
		       &ret_prop);

    if (ret_type == XA_STRING && ret_prop != NULL) {
	result = strdup (ret_prop);
	assert (result);
	XFree (ret_prop);
    } 
    return result;
}

MODULE = GNOME::GNORBA		PACKAGE = GNOME::GNORBA		

SV *
get_x_ns_ior()
    CODE:
    {
	Display *display;
	char *ior;
	int (*old_handler)(Display *, XErrorEvent *);
	
	display = XOpenDisplay(NULL);
	if (!display) {
	    RETVAL = newSVsv(&PL_sv_undef);
	} else {
	    old_handler = XSetErrorHandler (error_handler);
	    ior = get_ior (display);
	    XSetErrorHandler (old_handler);
	    
	    XCloseDisplay (display);

	    if (ior) {
		RETVAL = newSVpv (ior, 0);
	        free (ior);
	    } else {
		RETVAL = newSVpv ("", 0);
	    }
	}
    }
    OUTPUT:
    RETVAL

SV *
check_x_cookie(generate_func)
    SV *generate_func
    CODE:
    {
	Display *display;
	char *cookie;
	
	display = XOpenDisplay(NULL);
	if (!display) {
	    RETVAL = newSVsv(&PL_sv_undef);
	} else {
	    Atom prop = XInternAtom (display, "GNOME_SESSION_CORBA_COOKIE", False);
	    cookie = get_cookie (display, prop);
	    if (!cookie) {
		XGrabServer (display);
		cookie = get_cookie (display, prop);
		if (!cookie) {
		    cookie = get_cookie_from_func (generate_func);
		    XChangeProperty(display, DefaultRootWindow (display), 
				    prop, XA_STRING, 8, PropModeReplace,
				    cookie, strlen(cookie));
		}
		XUngrabServer (display);
		XFlush (display);
	    }

	    XCloseDisplay (display);

	    RETVAL = newSVpv (cookie, 0);
	    if (cookie)
	        free (cookie);
	}
    }
    OUTPUT:
    RETVAL

