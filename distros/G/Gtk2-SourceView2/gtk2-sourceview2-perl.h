#ifndef _SOURCEVIEW2_PERL_H_
#define _SOURCEVIEW2_PERL_H_

#include <gtk2perl.h>

#include <gtksourceview/gtksourcebuffer.h>
#include <gtksourceview/gtksourceiter.h>
#include <gtksourceview/gtksourcelanguage.h>
#include <gtksourceview/gtksourcelanguagemanager.h>
#include <gtksourceview/gtksourcemark.h>
#include <gtksourceview/gtksourceprintcompositor.h>
#include <gtksourceview/gtksourcestyle.h>
#include <gtksourceview/gtksourcestylescheme.h>
#include <gtksourceview/gtksourcestyleschememanager.h>
#include <gtksourceview/gtksourceview.h>
#include <gtksourceview/gtksourceview-typebuiltins.h>

#include "gtk2-sourceview2-autogen.h"


/**
 * Returns a gchar** in the stack.
 */
#define sourceview2perl_return_strv(func, free) \
do {\
	gchar **list = (gchar **) func; \
	if (list == NULL) { \
		XSRETURN_EMPTY; \
	} \
	else { \
		size_t i = 0; \
		for (; list[i] != NULL ; ++i) { \
			SV *sv = newSVGChar(list[i]); \
			XPUSHs(sv_2mortal(sv)); \
		} \
	} \
	if (free) g_strfreev(list); \
} while (FALSE)


/**
 * Generic function that acts as a setter for a property that's a string list.
 * This is the case for functions that accept a list of paths (strings).
 */
#define sourceview2perl_generic_set_dirs(func, arg) \
do {\
	gchar **dirs = NULL; \
	size_t count = items - 1; \
	size_t i     = 0; \
	\
	if (count > 0) { \
		if (count == 1 && !SvOK(ST(1))) { \
			/* Reset the values to the original list */ \
			dirs = NULL; \
		} \
		else { \
			dirs = g_new0(gchar *, items); \
			for (i = 0; i < count; ++i) { \
				dirs[i] = SvGChar(ST(i + 1)); \
			} \
		} \
	} \
	else { \
		/* Clear the current list */ \
		dirs = g_new0(gchar *, 1); \
		dirs[1] = NULL; \
	} \
	\
	func(arg, dirs); \
	g_free(dirs); \
} while (FALSE)


#endif /* _SOURCEVIEW2_PERL_H_ */
