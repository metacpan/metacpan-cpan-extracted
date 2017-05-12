/*
 * Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS)
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top level of this distribution
 * for the complete license terms.
 *
 */

#include "gnome2perl.h"

MODULE = Gnome2::URL	PACKAGE = Gnome2::URL	PREFIX = gnome_url_

=for apidoc __gerror__
=cut
##  gboolean gnome_url_show (const char *url, GError **error) 
gboolean
gnome_url_show (class, url)
	const char *url
    PREINIT:
	GError *error = NULL;
    CODE:
	RETVAL = gnome_url_show (url, &error);
	if (!RETVAL)
		gperl_croak_gerror("Gnome2::URL->show", error);
    OUTPUT:
	RETVAL


#if LIBGNOME_CHECK_VERSION (2, 2, 0)

=for apidoc __gerror__
=cut
##  gboolean gnome_url_show_with_env (const char *url, char **envp, GError **error) 
gboolean
gnome_url_show_with_env (class, url, env_ref)
	const char *url
	SV *env_ref
    PREINIT:
	char **envp;
	GError *error = NULL;
    CODE:
	envp = SvEnvArray (env_ref);

	RETVAL = gnome_url_show_with_env (url, envp, &error);
	if (!RETVAL)
		gperl_croak_gerror("Gnome2::URL->show", error);

	g_free (envp);
    OUTPUT:
	RETVAL

#endif
