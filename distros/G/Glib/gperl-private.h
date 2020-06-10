/*
 * Copyright (c) 2006, 2012 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

/*
 * This is a private header file intended for functions that are used in more
 * than one xs file.  These functions are not part of the public API.
 */

#ifndef _GPERL_PRIVATE_H_
#define _GPERL_PRIVATE_H_

/* If we're building against a very old version of GLib, provide a fallback
 * macro that doesn't do anything
 */
#ifndef G_GNUC_BEGIN_IGNORE_DEPRECATIONS
#define G_GNUC_BEGIN_IGNORE_DEPRECATIONS
#define G_GNUC_END_IGNORE_DEPRECATIONS
#endif

/*
 * Thread-safety macros and helpers
 */
void _gperl_set_master_interp (PerlInterpreter *interp);
PerlInterpreter *_gperl_get_master_interp (void);
#define GPERL_SET_CONTEXT						\
	{								\
		PerlInterpreter *me = _gperl_get_master_interp ();	\
		if (me && !PERL_GET_CONTEXT) {				\
			PERL_SET_CONTEXT (me);				\
		}			 				\
	}


#ifndef PERL_IMPLICIT_CONTEXT
GThread * _gperl_get_main_tid (void);
#endif

/*
 * Misc. stuff
 */
SV * _gperl_sv_from_value_internal (const GValue * value, gboolean copy_boxed);

SV * _gperl_fetch_wrapper_key (GObject * object, const char * name, gboolean create);

#define SAVED_STACK_SV(expr)			\
	({					\
		SV *_saved_stack_sv;		\
		PUTBACK;			\
		_saved_stack_sv = expr;		\
		SPAGAIN;			\
		_saved_stack_sv;		\
	})
#define SAVED_STACK_PUSHs(expr)					\
	(void) ({						\
		SV *_saved_stack_sv = SAVED_STACK_SV (expr);	\
		PUSHs (_saved_stack_sv);			\
	})
#define SAVED_STACK_XPUSHs(expr)				\
	(void) ({						\
		SV *_saved_stack_sv = SAVED_STACK_SV (expr);	\
		XPUSHs (_saved_stack_sv);			\
	})

#endif /* _GPERL_PRIVATE_H_ */
