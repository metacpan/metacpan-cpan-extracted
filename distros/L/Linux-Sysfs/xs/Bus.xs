#include "perl_sysfs.h"

MODULE = Linux::Sysfs::Bus	PACKAGE = Linux::Sysfs::Bus

struct sysfs_bus*
open(class, name)
		const char* name
	CODE:
		RETVAL = sysfs_open_bus(name);
	OUTPUT:
		RETVAL

void
close(bus)
		struct sysfs_bus* bus
	CODE:
		sysfs_close_bus(bus);

void
get_devices(bus)
		struct sysfs_bus* bus
	PREINIT:
		struct dlist* dev_list = NULL;
		struct sysfs_device* dev = NULL;
	PPCODE:
		dev_list = sysfs_get_bus_devices(bus);

		if (dev_list == NULL)
			XSRETURN_EMPTY;

		EXTEND(SP, dev_list->count);
		dlist_for_each_data(dev_list, dev, struct sysfs_device) {
			PUSHs(sv_2mortal( perl_sysfs_new_sv_from_ptr(dev, "Linux::Sysfs::Device") ));
		}

void
get_drivers(bus)
		struct sysfs_bus* bus
	PREINIT:
		struct dlist* drv_list = NULL;
		struct sysfs_driver* drv = NULL;
	PPCODE:
		drv_list = sysfs_get_bus_drivers(bus);

		if (drv_list == NULL)
			XSRETURN_EMPTY;

		EXTEND(SP, drv_list->count);
		dlist_for_each_data(drv_list, drv, struct sysfs_driver) {
			PUSHs(sv_2mortal( perl_sysfs_new_sv_from_ptr(drv, "Linux::Sysfs::Driver") ));
		}

struct sysfs_device*
get_device(bus, id)
		struct sysfs_bus* bus
		const char* id
	CODE:
		RETVAL = sysfs_get_bus_device(bus, id);
	OUTPUT:
		RETVAL

struct sysfs_driver*
get_driver(bus, drvname)
		struct sysfs_bus* bus
		const char* drvname
	CODE:
		RETVAL = sysfs_get_bus_driver(bus, drvname);
	OUTPUT:
		RETVAL

char*
name(bus)
		struct sysfs_bus* bus
	CODE:
		RETVAL = bus->name;
	OUTPUT:
		RETVAL

char*
path(bus)
		struct sysfs_bus* bus
	CODE:
		RETVAL = bus->path;
	OUTPUT:
		RETVAL
