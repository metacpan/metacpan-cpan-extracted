/*
 * Copyright (C) 2005 by the gtk2-perl team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * $Id$
 */

#include "gst2perl.h"

MODULE = GStreamer	PACKAGE = GStreamer	PREFIX = gst_

BOOT:
#include "register.xsh"
#include "boot.xsh"
	/* FIXME: This seems to have no effect since libgstreamer installs its
	 * own log handler.  Since it's installed later, it seems to be
	 * preferred, so our's is never actually invoked. */
	gperl_handle_logs_for ("GStreamer");

# --------------------------------------------------------------------------- #

=for apidoc __hide__
=cut
void
GET_VERSION_INFO (class)
    PPCODE:
	EXTEND (SP, 3);
	/* 0.10.17 provides these macros, but with a different name. */
#if GST_CHECK_VERSION (0, 10, 17)
	PUSHs (sv_2mortal (newSViv (GST_VERSION_MAJOR)));
	PUSHs (sv_2mortal (newSViv (GST_VERSION_MINOR)));
	PUSHs (sv_2mortal (newSViv (GST_VERSION_MICRO)));
#else
	PUSHs (sv_2mortal (newSViv (GST_MAJOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GST_MINOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GST_MICRO_VERSION)));
#endif
	PERL_UNUSED_VAR (ax);

=for apidoc __hide__
=cut
bool
CHECK_VERSION (class, major, minor, micro)
	int major
	int minor
	int micro
    CODE:
	RETVAL = GST_CHECK_VERSION (major, minor, micro);
    OUTPUT:
	RETVAL

=for apidoc __hide__
=cut
# void gst_version (guint *major, guint *minor, guint *micro, guint *nano);
void
gst_version (class)
    PREINIT:
	guint major, minor, micro, nano;
    PPCODE:
	PERL_UNUSED_VAR (ax);
	gst_version (&major, &minor, &micro, &nano);
	EXTEND (sp, 3);
	PUSHs (sv_2mortal (newSVuv (major)));
	PUSHs (sv_2mortal (newSVuv (minor)));
	PUSHs (sv_2mortal (newSVuv (micro)));
	PUSHs (sv_2mortal (newSVuv (nano)));

=for apidoc __hide__
=cut
# gchar * gst_version_string (void);
gchar_own *
gst_version_string (class)
    C_ARGS:
	/* void */

# --------------------------------------------------------------------------- #

=for apidoc __hide__
=cut
# void gst_init (int *argc, char **argv[]);
void
gst_init (class)
    PREINIT:
	GPerlArgv *pargv;
    CODE:
	pargv = gperl_argv_new ();

	gst_init (&pargv->argc, &pargv->argv);

	gperl_argv_update (pargv);
	gperl_argv_free (pargv);

=for apidoc __hide__
=cut
# gboolean gst_init_check (int *argc, char **argv[], GError ** err);
gboolean
gst_init_check (class)
    PREINIT:
	GPerlArgv *pargv;
	GError *error = NULL;
    CODE:
	pargv = gperl_argv_new ();

	RETVAL = gst_init_check (&pargv->argc, &pargv->argv, &error);

	gperl_argv_update (pargv);
	gperl_argv_free (pargv);

	if (error)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL

# GOptionGroup * gst_init_get_option_group (void);

=for apidoc __hide__
=cut
# void gst_deinit (void);
void
gst_deinit (class)
    C_ARGS:
	/* void */

# --------------------------------------------------------------------------- #

=for apidoc __hide__
=cut
# GstElement* gst_parse_launch (const gchar *pipeline_description, GError **error);
GstElement *
gst_parse_launch (pipeline_description)
	const gchar *pipeline_description
    PREINIT:
	GError *error = NULL;
    CODE:
	RETVAL = gst_parse_launch (pipeline_description, &error);
	if (!RETVAL)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL
