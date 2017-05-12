#include "perl_sysfs.h"

MODULE = Linux::Sysfs::Class	PACKAGE = Linux::Sysfs::Class

struct sysfs_class*
open(class, name)
		const char* name
	CODE:
		RETVAL = sysfs_open_class(name);
	OUTPUT:
		RETVAL

void
close(class)
		struct sysfs_class* class
	CODE:
		sysfs_close_class(class);

struct sysfs_class_device*
get_device(class, name)
		struct sysfs_class* class
		const char* name
	CODE:
		RETVAL = sysfs_get_class_device(class, name);
	OUTPUT:
		RETVAL

void
get_devices(class)
		struct sysfs_class* class
	PREINIT:
		struct dlist* dev_list = NULL;
		struct sysfs_class_device* dev = NULL;
	PPCODE:
		dev_list = sysfs_get_class_devices(class);

		if (dev_list == NULL)
			XSRETURN_EMPTY;

		EXTEND(SP, dev_list->count);
		dlist_for_each_data(dev_list, dev, struct sysfs_class_device) {
			PUSHs(sv_2mortal( perl_sysfs_new_sv_from_ptr(dev, "Linux::Sysfs::ClassDevice") ));
		}

char*
name(class)
		struct sysfs_class* class
	CODE:
		RETVAL = class->name;
	OUTPUT:
		RETVAL

char*
path(class)
		struct sysfs_class* class
	CODE:
		RETVAL = class->path;
	OUTPUT:
		RETVAL
