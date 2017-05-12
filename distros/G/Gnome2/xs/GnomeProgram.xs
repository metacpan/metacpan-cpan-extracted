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

static const GnomeModuleInfo *
handle_module_info (SV * module_info)
{
	const GnomeModuleInfo * real_module_info = NULL;

	if (!module_info || !SvTRUE (module_info)) {
		/* go ahead and pass NULL.  you get libgnome initialized. */
		/* FIXME FIXME is it right to change default to libgnomeui? */
		real_module_info = LIBGNOMEUI_MODULE;
	} else if (SvPOK (module_info)) {
		/* name of a module.  this is a limited-support hack. */
		char * modname = SvPV_nolen (module_info);
		if (strEQ ("libgnome", modname)) {
			real_module_info = LIBGNOME_MODULE;
		} else if (strEQ ("libgnomeui", modname)) {
			real_module_info = LIBGNOMEUI_MODULE;
		} else {
			croak ("you passed a string for module_info, but it wasn't one of 'libgnome' or 'libgnomeui'");
		}
	} else {
		real_module_info = SvGnomeModuleInfo (module_info);
	}

	return real_module_info;
}

MODULE = Gnome2::Program	PACKAGE = Gnome2::Program	PREFIX = gnome_program_

=for apidoc

The list argument is for property-value pairs.

=cut
##  GnomeProgram * gnome_program_init (const char *app_id, const char *app_version, const GnomeModuleInfo *module_info, int argc, char **argv, const char *first_property_name, ...) 
GnomeProgram *
gnome_program_init (class, app_id, app_version, module_info=NULL, ...)
	const char * app_id
	const char * app_version
	SV * module_info
    PREINIT:
	int i;
	GPerlArgv *pargv;
	const GnomeModuleInfo * real_module_info = NULL;
    CODE:
#define FIRST_VAR_ARG 4

	/* check validity of stack item count before doing anything else */
	if (items > FIRST_VAR_ARG && 0 != ((items - FIRST_VAR_ARG) % 2)) {
		/* caller didn't specify an even number of parameters... */
		croak ("Usage: Gnome2::Program->init (app_id, app_version, module_info)\n"
		       "   or: Gnome2::Program->init (app_id, app_version, module_info, prop => val, ...)\n"
		       "   there may be any number of prop/val pairs, but there must be a value\n"
		       "   for every prop");
	}

	/* let's see what the user passed for module_info */
	real_module_info = handle_module_info (module_info);

	/* we're good to go.  let's get a hold of @ARGV and $0 so we can
	 * synthesize the argv that gnome_program_init wants. */
	pargv = gperl_argv_new ();
	/* note that we have *not* modifed @ARGV.
	 */
#if LIBGNOME_CHECK_VERSION (2, 8, 0)
{
	GObjectClass *class;
	GParameter *params = NULL;
	guint nparams;
	int j;

	class = g_type_class_ref (GNOME_TYPE_PROGRAM);

	nparams = (items - FIRST_VAR_ARG) / 2;
	params = g_new0 (GParameter, nparams);

	/* get properties off the stack and set them */
	for (i = FIRST_VAR_ARG, j = 0 ; i < items ; i += 2, j++) {
		GType type;

		params[j].name = SvGChar (ST (i));

		/* Map GNOME_CLIENT_PARAM_SM_CONNECT to G_TYPE_BOOLEAN
		 * manually.  It's installed into the GnomeProgram class by
		 * libgnomeui when its module is loaded.  But that happens as
		 * part of gnome_program_init_paramv which we call below.  So
		 * when we try to find out the correct type for sm-connect
		 * *now*, the type system will complain that GnomeProgram has
		 * no such property.
		 */
		if (gperl_str_eq (params[j].name, GNOME_CLIENT_PARAM_SM_CONNECT)) {
			type = G_TYPE_BOOLEAN;
		} else {
			GParamSpec * pspec =
			  g_object_class_find_property (class, params[j].name);
			if (!pspec)
				/* we should do a lot more cleanup here,
				 * in principle, but the GnomeProgram is a
				 * singleton, and most people aren't going to
				 * accept an exception on initializing it. */
				croak ("property %s not found in object class %s",
				       params[j].name,
				       g_type_name (GNOME_TYPE_PROGRAM));
			type = G_PARAM_SPEC_VALUE_TYPE (pspec);
		}

		g_value_init (&params[j].value, type);
		gperl_value_from_sv (&params[j].value, ST (i+1));
	}

	RETVAL = gnome_program_init_paramv (GNOME_TYPE_PROGRAM,
	                                    app_id, app_version,
	                                    real_module_info,
	                                    pargv->argc, pargv->argv,
	                                    nparams, params);

	for (j = 0 ; j < nparams ; j++) {
		g_value_unset (&params[j].value);
	}

	g_free (params);
	g_type_class_unref (class);
}
#else
	RETVAL = gnome_program_init (app_id, app_version, real_module_info,
	                             pargv->argc, pargv->argv,
	                             GNOME_PARAM_NONE);

	/* get properties off the stack and set them */
	for (i = FIRST_VAR_ARG ; i < items ; i += 2) {
		const char * property_name;
		GValue gvalue = {0,};
		GParamSpec * pspec;

		property_name = SvGChar (ST (i));
		pspec = g_object_class_find_property 
		                          (G_OBJECT_GET_CLASS (RETVAL),
		                          property_name);
		if (!pspec)
			/* we should do a lot more cleanup here, 
			 * in principle, but the GnomeProgram is a 
			 * singleton, and most people aren't going to
			 * accept an exception on initializing it. */
			croak ("property %s not found in object class %s",
			       property_name, G_OBJECT_TYPE_NAME (RETVAL));

		g_value_init (&gvalue, G_PARAM_SPEC_VALUE_TYPE (pspec));
		gperl_value_from_sv (&gvalue, ST (i+1));
		g_object_set_property (G_OBJECT (RETVAL), property_name,
		                       &gvalue);
		g_value_unset (&gvalue);
	}
#endif

	gperl_argv_free (pargv);
    OUTPUT:
	RETVAL


##  GnomeProgram * gnome_program_get (void) 
GnomeProgram_ornull *
gnome_program_get_program (class)
    CODE:
	RETVAL = gnome_program_get ();
    OUTPUT:
	RETVAL
	

const char * gnome_program_get_human_readable_name (GnomeProgram * program);


const char* gnome_program_get_app_id (GnomeProgram *program);


const char* gnome_program_get_app_version (GnomeProgram *program);


=for apidoc

Returns a list of locations.

=cut
##  gchar * gnome_program_locate_file (GnomeProgram *program, GnomeFileDomain domain, const gchar *file_name, gboolean only_if_exists, GSList **ret_locations) 
void
gnome_program_locate_file (program, domain, file_name, only_if_exists)
	GnomeProgram *program
	GnomeFileDomain domain
	const gchar *file_name
	gboolean only_if_exists
    PREINIT:
	gchar *path;
	GSList *i, *ret_locations = NULL;
    PPCODE:
	path = gnome_program_locate_file (program, domain, file_name,
	                                  only_if_exists, &ret_locations);

	if (path) {
		XPUSHs (sv_2mortal (newSVGChar (path)));
		g_free (path);
	}

	for (i = ret_locations; i != NULL; i = i->next) {
		XPUSHs (sv_2mortal (newSVGChar ((gchar *) i->data)));
		g_free (i->data);
	}

	g_slist_free (ret_locations);


##  void gnome_program_module_register (const GnomeModuleInfo *module_info) 
void
gnome_program_module_register (class, module_info)
	SV * module_info
    PREINIT:
	const GnomeModuleInfo * real_module_info = NULL;
    CODE:
	real_module_info = handle_module_info (module_info);
	gnome_program_module_register(real_module_info);


##  gboolean gnome_program_module_registered (const GnomeModuleInfo *module_info) 
gboolean
gnome_program_module_registered (class, module_info)
	SV * module_info
    PREINIT:
	const GnomeModuleInfo * real_module_info = NULL;
    CODE:
	real_module_info = handle_module_info (module_info);
	RETVAL = gnome_program_module_registered (real_module_info);
    OUTPUT:
	RETVAL


##  const GnomeModuleInfo * gnome_program_module_load (const char * mod_name) 
GnomeModuleInfo *
gnome_program_module_load (class, mod_name)
	const char * mod_name
    CODE:
	/* just to keep the compiler from complaining about const */
	RETVAL = (GnomeModuleInfo*)gnome_program_module_load(mod_name);
    OUTPUT:
	RETVAL
