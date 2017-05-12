#include "perl_sysfs.h"

MODULE = Linux::Sysfs::Module	PACKAGE = Linux::Sysfs::Module

struct sysfs_module*
open(class, name)
		const char* name
	CODE:
		RETVAL = sysfs_open_module(name);
	OUTPUT:
		RETVAL

struct sysfs_module*
open_path(class, path)
		const char* path
	CODE:
		RETVAL = sysfs_open_module_path(path);
	OUTPUT:
		RETVAL

void
close(module)
		struct sysfs_module* module
	CODE:
		sysfs_close_module(module);

void
get_parms(module)
		struct sysfs_module* module
	PREINIT:
		struct dlist* parms_list = NULL;
		struct sysfs_attribute* parm = NULL;
	PPCODE:
		parms_list = sysfs_get_module_parms(module);

		if (parms_list == NULL)
			XSRETURN_EMPTY;

		EXTEND(SP, parms_list->count);
		dlist_for_each_data(parms_list, parm, struct sysfs_attribute) {
			PUSHs(sv_2mortal( perl_sysfs_new_sv_from_ptr(parm, "Linux::Sysfs::Attribute") ));
		}

void
get_sections(module)
		struct sysfs_module* module
	PREINIT:
		struct dlist* sections_list = NULL;
		struct sysfs_attribute* section = NULL;
	PPCODE:
		sections_list = sysfs_get_module_sections(module);

		if (sections_list == NULL)
			XSRETURN_EMPTY;

		EXTEND(SP, sections_list->count);
		dlist_for_each_data(sections_list, section, struct sysfs_attribute) {
			PUSHs(sv_2mortal( perl_sysfs_new_sv_from_ptr(section, "Linux::Sysfs::Attribute") ));
		}

void
get_attributes(module)
		struct sysfs_module* module
	ALIAS:
		get_attrs = 1
	PREINIT:
		struct dlist* attr_list = NULL;
		struct sysfs_attribute* attr = NULL;
	PPCODE:
		PERL_UNUSED_VAR(ix);
		attr_list = sysfs_get_module_attributes(module);

		if (attr_list == NULL)
			XSRETURN_EMPTY;

		EXTEND(SP, attr_list->count);
		dlist_for_each_data(attr_list, attr, struct sysfs_attribute) {
			PUSHs(sv_2mortal( perl_sysfs_new_sv_from_ptr(attr, "Linux::Sysfs::Attribute") ));
		}

struct sysfs_attribute*
get_attribute(module, name)
		struct sysfs_module* module
		const char* name
	ALIAS:
		get_attr = 1
	CODE:
		PERL_UNUSED_VAR(ix);
		RETVAL = sysfs_get_module_attr(module, name);
	OUTPUT:
		RETVAL


struct sysfs_attribute*
get_parm(module, parm)
		struct sysfs_module* module
		const char* parm
	CODE:
		RETVAL = sysfs_get_module_parm(module, parm);
	OUTPUT:
		RETVAL

struct sysfs_attribute*
get_section(module, section)
		struct sysfs_module* module
		const char* section
	CODE:
		RETVAL = sysfs_get_module_section(module, section);
	OUTPUT:
		RETVAL

char*
name(module)
		struct sysfs_module* module
	CODE:
		RETVAL = module->name;
	OUTPUT:
		RETVAL

char*
path(module)
		struct sysfs_module* module
	CODE:
		RETVAL = module->path;
	OUTPUT:
		RETVAL
