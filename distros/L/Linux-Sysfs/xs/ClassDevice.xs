#include "perl_sysfs.h"

MODULE = Linux::Sysfs::ClassDevice	PACKAGE = Linux::Sysfs::ClassDevice

struct sysfs_class_device*
open(class, classname, name)
		const char* classname
		const char* name
	CODE:
		RETVAL = sysfs_open_class_device(classname, name);
	OUTPUT:
		RETVAL

struct sysfs_class_device*
open_path(class, path)
		const char* path
	CODE:
		RETVAL = sysfs_open_class_device_path(path);
	OUTPUT:
		RETVAL

void
close(classdev)
		struct sysfs_class_device* classdev
	CODE:
		sysfs_close_class_device(classdev);

struct sysfs_class_device*
get_parent(classdev)
		struct sysfs_class_device* classdev
	CODE:
		RETVAL = sysfs_get_classdev_parent(classdev);
	OUTPUT:
		RETVAL

struct sysfs_attribute*
get_attr(classdev, name)
		struct sysfs_class_device* classdev
		const char* name
	CODE:
		RETVAL = sysfs_get_classdev_attr(classdev, name);
	OUTPUT:
		RETVAL

void
get_attrs(classdev)
		struct sysfs_class_device* classdev
	ALIAS:
		get_attributes = 1
	PREINIT:
		struct dlist* attr_list = NULL;
		struct sysfs_attribute* attr = NULL;
	PPCODE:
		PERL_UNUSED_VAR(ix);
		attr_list = sysfs_get_classdev_attributes(classdev);

		if (attr_list == NULL)
			XSRETURN_EMPTY;

		EXTEND(SP, attr_list->count);
		dlist_for_each_data(attr_list, attr, struct sysfs_attribute) {
			PUSHs(sv_2mortal( perl_sysfs_new_sv_from_ptr(attr, "Linux::Sysfs::Attribute") ));
		}

struct sysfs_device*
get_device(classdev)
		struct sysfs_class_device* classdev
	CODE:
		RETVAL = sysfs_get_classdev_device(classdev);
	OUTPUT:
		RETVAL

char*
name(classdev)
		struct sysfs_class_device* classdev
	CODE:
		RETVAL = classdev->name;
	OUTPUT:
		RETVAL

char*
path(classdev)
		struct sysfs_class_device* classdev
	CODE:
		RETVAL = classdev->path;
	OUTPUT:
		RETVAL

char*
classname(classdev)
		struct sysfs_class_device* classdev
	CODE:
		RETVAL = classdev->classname;
	OUTPUT:
		RETVAL
