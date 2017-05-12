#include "perl_sysfs.h"

MODULE = Linux::Sysfs::Driver	PACKAGE = Linux::Sysfs::Driver

struct sysfs_driver*
open(class, bus_name, drv_name)
		const char* bus_name
		const char* drv_name
	CODE:
		RETVAL = sysfs_open_driver(bus_name, drv_name);
	OUTPUT:
		RETVAL

struct sysfs_driver*
open_path(class, path)
		const char* path
	CODE:
		RETVAL = sysfs_open_driver_path(path);
	OUTPUT:
		RETVAL

void
close(driver)
		struct sysfs_driver* driver
	CODE:
		sysfs_close_driver(driver);

struct sysfs_attribute*
get_attr(driver, name)
		struct sysfs_driver* driver
		const char* name
	ALIAS:
		get_attribute = 1
	CODE:
		PERL_UNUSED_VAR(ix);
		RETVAL = sysfs_get_driver_attr(driver, name);
	OUTPUT:
		RETVAL

void
get_attrs(driver)
		struct sysfs_driver* driver
	ALIAS:
		get_attributes = 1
	PREINIT:
		struct dlist* attr_list = NULL;
		struct sysfs_attribute* attr = NULL;
	PPCODE:
		PERL_UNUSED_VAR(ix);
		attr_list = sysfs_get_driver_attributes(driver);

		if (attr_list == NULL)
			XSRETURN_EMPTY;

		EXTEND(SP, attr_list->count);
		dlist_for_each_data(attr_list, attr, struct sysfs_attribute) {
			PUSHs(sv_2mortal( perl_sysfs_new_sv_from_ptr(attr, "Linux::Sysfs::Attribute") ));
		}

void
get_devices(driver)
		struct sysfs_driver* driver
	PREINIT:
		struct dlist* dev_list = NULL;
		struct sysfs_device* dev = NULL;
	PPCODE:
		dev_list = sysfs_get_driver_devices(driver);

		if (dev_list == NULL)
			XSRETURN_EMPTY;

		EXTEND(SP, dev_list->count);
		dlist_for_each_data(dev_list, dev, struct sysfs_device) {
			PUSHs(sv_2mortal( perl_sysfs_new_sv_from_ptr(dev, "Linux::Sysfs::Device") ));
		}

struct sysfs_module*
get_module(driver)
		struct sysfs_driver* driver
	CODE:
		RETVAL = sysfs_get_driver_module(driver);
	OUTPUT:
		RETVAL

char*
name(driver)
		struct sysfs_driver* driver
	CODE:
		RETVAL = driver->name;
	OUTPUT:
		RETVAL

char*
path(driver)
		struct sysfs_driver* driver
	CODE:
		RETVAL = driver->path;
	OUTPUT:
		RETVAL

char*
bus(driver)
		struct sysfs_driver* driver
	CODE:
		RETVAL = driver->bus;
	OUTPUT:
		RETVAL
