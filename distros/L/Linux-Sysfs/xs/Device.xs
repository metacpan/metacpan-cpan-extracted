#include "perl_sysfs.h"

MODULE = Linux::Sysfs::Device	PACKAGE = Linux::Sysfs::Device

struct sysfs_device*
open(class, bus, bus_id)
		const char* bus
		const char* bus_id
	CODE:
		RETVAL = sysfs_open_device(bus, bus_id);
	OUTPUT:
		RETVAL

struct sysfs_device*
open_path(class, path)
		const char* path
	CODE:
		RETVAL = sysfs_open_device_path(path);
	OUTPUT:
		RETVAL

void
close(dev)
		struct sysfs_device* dev
	CODE:
		sysfs_close_device(dev);

void
close_tree(dev)
		struct sysfs_device* dev
	CODE:
		sysfs_close_device_tree(dev);

struct sysfs_device*
get_parent(dev)
		struct sysfs_device* dev
	CODE:
		RETVAL = sysfs_get_device_parent(dev);
	OUTPUT:
		RETVAL

void
get_bus(dev)
		struct sysfs_device* dev
	CODE:
		if (sysfs_get_device_bus(dev) == 0) {
			XSRETURN_YES;
		} else {
			XSRETURN_NO;
		}

struct sysfs_attribute*
get_attr(dev, name)
		struct sysfs_device* dev
		const char* name
	ALIAS:
		get_attribute = 1
	CODE:
		PERL_UNUSED_VAR(ix);
		RETVAL = sysfs_get_device_attr(dev, name);
	OUTPUT:
		RETVAL

void
get_attrs(dev)
		struct sysfs_device* dev
	ALIAS:
		get_attributes = 1
	PREINIT:
		struct dlist* attr_list = NULL;
		struct sysfs_attribute* attr = NULL;
	PPCODE:
		PERL_UNUSED_VAR(ix);
		attr_list = sysfs_get_device_attributes(dev);

		if (attr_list == NULL)
			XSRETURN_EMPTY;

		EXTEND(SP, attr_list->count);
		dlist_for_each_data(attr_list, attr, struct sysfs_attribute) {
			PUSHs(sv_2mortal( perl_sysfs_new_sv_from_ptr(attr, "Linux::Sysfs::Attribute") ));
		}

char*
name(dev)
		struct sysfs_device* dev
	CODE:
		RETVAL = dev->name;
	OUTPUT:
		RETVAL

char*
path(dev)
		struct sysfs_device* dev
	CODE:
		RETVAL = dev->path;
	OUTPUT:
		RETVAL

char*
bus_id(dev)
		struct sysfs_device* dev
	CODE:
		RETVAL = dev->bus_id;
	OUTPUT:
		RETVAL

char*
bus(dev)
		struct sysfs_device* dev
	CODE:
		RETVAL = dev->bus;
	OUTPUT:
		RETVAL

char*
driver_name(dev)
		struct sysfs_device* dev
	CODE:
		RETVAL = dev->driver_name;
	OUTPUT:
		RETVAL
