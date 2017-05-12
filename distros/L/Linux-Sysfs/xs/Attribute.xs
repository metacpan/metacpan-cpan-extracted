#include "perl_sysfs.h"

MODULE = Linux::Sysfs::Attribute	PACKAGE = Linux::Sysfs::Attribute

struct sysfs_attribute*
open(class, path)
		const char* path
	CODE:
		RETVAL = sysfs_open_attribute(path);
	OUTPUT:
		RETVAL

void
close(attr)
		struct sysfs_attribute* attr
	CODE:
		sysfs_close_attribute(attr);

void
read(attr)
		struct sysfs_attribute* attr
	CODE:
		if (sysfs_read_attribute(attr) == 0) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }

void
write(attr, sv)
		struct sysfs_attribute* attr
		SV* sv
    PREINIT:
        char* value;
        STRLEN len;
	CODE:
        value = SvPV(sv, len);
		if (sysfs_write_attribute(attr, value, len) == 0) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }

char*
value(attr)
		struct sysfs_attribute* attr
	CODE:
		RETVAL = attr->value;
	OUTPUT:
		RETVAL

bool
can_read(attr)
		struct sysfs_attribute* attr
	CODE:
		RETVAL = attr->method & SYSFS_METHOD_SHOW;
	OUTPUT:
		RETVAL

bool
can_write(attr)
		struct sysfs_attribute* attr
	CODE:
		RETVAL = attr->method & SYSFS_METHOD_STORE;
	OUTPUT:
		RETVAL

char*
name(attr)
		struct sysfs_attribute* attr
	CODE:
		RETVAL = attr->name;
	OUTPUT:
		RETVAL

char*
path(attr)
		struct sysfs_attribute* attr
	CODE:
		RETVAL = attr->path;
	OUTPUT:
		RETVAL
