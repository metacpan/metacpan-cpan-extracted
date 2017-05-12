/* This is the module loader. It provides the facility for loading match
 * and target modules, which will do whatever relevant handling is necessary
 * for the data associated with matches and targets in the rules.
 */

/*
 * Author: Derrik Pates <dpates@dsdk12.net>
 *
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */


#define __USE_GNU
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* for dlopen()/dlsym() and associated symbols */
#include <dlfcn.h>
#include <stdio.h>

/* for getenv() */
#include <stdlib.h>

#include <string.h>

#include "loader.h"

/* Keep a list of the modules we've loaded */
static ModuleDef *module_list = NULL;

/* Keep an internal reference count; when this is decremented to 0, release
 * any loaded modules. */
static int _refcount = 0;

static void register_module(ModuleDef *, HANDLE *, void *);

/* If we have a known built-in target, then we use the 'standard' target
 * module */
static bool use_std_target(char *targetname) {
	if(!strcmp(targetname, ""))
		return(TRUE);
	if(!strcmp(targetname, "ACCEPT"))
		return(TRUE);
	if(!strcmp(targetname, "DROP"))
		return(TRUE);
	if(!strcmp(targetname, "QUEUE"))
		return(TRUE);
	if(!strcmp(targetname, "RETURN"))
		return(TRUE);

	return(FALSE);
}

/* Load module, using a private call */
static ModuleDef *find_module_int(char *name, ModuleType type,
				HANDLE *table, bool dont_load) {
	ModuleDef *ptr = NULL;
	void *libhandle;
	ModuleDef *(*initf)(void);
	char *dlname = name;

#ifdef INET6
	/* What. the. hell. This is an ugly, ugly hack. */
	if (!strcmp(name, "icmpv6") || !strcmp(name, "ipv6-icmp") ||
					!strcmp(name, "icmp6")) {
		dlname = "icmpv6";
		name = "icmp6";
	}
#endif /* INET6 */

	/* If we're looking for a target module, and it's a built-in target or a
	 * chain, then load the 'standard' target module instead... */
	if((type == MODULE_TARGET) && (use_std_target(name) ||
							(table && IS_CHAIN(name, *table))))
		dlname = name = STD_TARGET;

	/* If the module we need has already been loaded, then just kick back
	 * a pointer to its data structure */
	for(ptr = module_list; ptr; ptr = ptr->next) {
		if(!strcmp(ptr->name, name) && type == ptr->type)
			return(ptr);
	}

	/* Ok, it's not loaded... if the don't load flag is set, don't try to
	 * dynamically load a module (normally only for this routine to call
	 * itself */
	if(!dont_load) {
		char *path, *basepath = NULL;
		basepath = getenv("IPT_MODPATH");
		if (!basepath || !strcmp(basepath, ""))
			basepath = MODULE_PATH;
#ifdef INET6
		asprintf(&path, "%s/ip6t_pl_%s.so", basepath, dlname);
#else /* !INET6 */
		asprintf(&path, "%s/ipt_pl_%s.so", basepath, dlname);
#endif /* INET6 */
		if((libhandle = dlopen(path, RTLD_NOW))) {
			initf = dlsym(libhandle, "init");
			register_module(initf(), table, libhandle);
			if(!(ptr = find_module_int(name, type, table, TRUE)))
				SET_ERRSTR("Couldn't lookup module %s after registration", name);
		} else
			SET_ERRSTR("dlopen() failed: %s", dlerror());
		free(path);
	}
	return(ptr);
}

/* Look up, or load, a module for me */
ModuleDef *ipt_find_module(char *name, ModuleType type, HANDLE *table) {
	return find_module_int(name, type, table, FALSE);
}

/* Keep an internal count of how many times we've been instantiated, so that
 * we can unload the modules we've loaded */
void ipt_loader_setup(void) {
	_refcount++;
}

/* Release all loaded modules when the refcount is 0 */
void ipt_release_modules(void) {
	ModuleDef *next;
	--_refcount;
	if (_refcount < 0)
		printf("refcount less than 0, wtf?\n");
	if (_refcount)
		return;
	/* This way, if someone really doesn't want to unload the modules, they
	 * can say so. This is useful with tools like valgrind and gdb. */
	if (!getenv("IPT_DONT_UNLOAD")) {
		while (module_list) {
			next = module_list->next;
			dlclose(module_list->libh);
			module_list = next;
		}
	}
}

/* Indoctrinate the newly-loaded module into the ways of our lands... */
static void register_module(ModuleDef *def, HANDLE *table,
				void *libhandle) {
	ModuleDef *i;
	def->libh = libhandle;
	/* Make sure this module isn't already loaded - if it is, something is
	 * broken. This should never happen, but if it does, then we probably 
	 * have a faulty module. */
	if(find_module_int(def->name, def->type, table, TRUE)) {
		fprintf(stderr, "Uhh. I already know module %s, something bad "
						"happened\n", def->name);
		return;
	}

	/* Check the size alignment - if alignment is wrong, we've got problems */
	if(def->size != ALIGN(def->size)) {
		fprintf(stderr, "Size is not properly aligned for this "
						"architecture!\n");
		exit(1);
	}

	/* Go ahead and stash the newly loaded module, now that we are reasonably
	 * sure that everything is OK. */
	for(i = module_list; i && i->next; i = i->next);
	if(i)
		i->next = def;
	else
		module_list = def;
}

/* vim: ts=4
 */
