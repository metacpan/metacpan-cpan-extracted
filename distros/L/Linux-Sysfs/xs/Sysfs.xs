#include "perl_sysfs.h"

void
register_constants(void) {
	SV* constant;

	constant = get_sv("Linux::Sysfs::FSTYPE_NAME", 1);
	sv_setpv(constant, SYSFS_FSTYPE_NAME);

	constant = get_sv("Linux::Sysfs::PROC_MNTS", 1);
	sv_setpv(constant, SYSFS_PROC_MNTS);

	constant = get_sv("Linux::Sysfs::BUS_NAME", 1);
	sv_setpv(constant, SYSFS_BUS_NAME);

	constant = get_sv("Linux::Sysfs::CLASS_NAME", 1);
	sv_setpv(constant, SYSFS_CLASS_NAME);

	constant = get_sv("Linux::Sysfs::BLOCK_NAME", 1);
	sv_setpv(constant, SYSFS_BLOCK_NAME);

	constant = get_sv("Linux::Sysfs::DEVICES_NAME", 1);
	sv_setpv(constant, SYSFS_DEVICES_NAME);

	constant = get_sv("Linux::Sysfs::DRIVERS_NAME", 1);
	sv_setpv(constant, SYSFS_DRIVERS_NAME);

	constant = get_sv("Linux::Sysfs::MODULE_NAME", 1);
	sv_setpv(constant, SYSFS_MODULE_NAME);

	constant = get_sv("Linux::Sysfs::NAME_ATTRIBUTE", 1);
	sv_setpv(constant, SYSFS_NAME_ATTRIBUTE);

	constant = get_sv("Linux::Sysfs::MOD_PARM_NAME", 1);
	sv_setpv(constant, SYSFS_MOD_PARM_NAME);

	constant = get_sv("Linux::Sysfs::MOD_SECT_NAME", 1);
	sv_setpv(constant, SYSFS_MOD_SECT_NAME);

	constant = get_sv("Linux::Sysfs::UNKNOWN", 1);
	sv_setpv(constant, SYSFS_UNKNOWN);

	constant = get_sv("Linux::Sysfs::PATH_ENV", 1);
	sv_setpv(constant, SYSFS_PATH_ENV);
}

MODULE = Linux::Sysfs	PACKAGE = Linux::Sysfs	PREFIX = sysfs_

# utils

char*
sysfs_get_mnt_path(class)
	PREINIT:
		char sysfs_mnt_path[SYSFS_PATH_MAX];
	CODE:
		if (sysfs_get_mnt_path(sysfs_mnt_path, SYSFS_PATH_MAX) != 0)
            XSRETURN_UNDEF;

		RETVAL = sysfs_mnt_path;
	OUTPUT:
		RETVAL

BOOT:
	PERL_SYSFS_BOOT(boot_Linux__Sysfs__Attribute);
	PERL_SYSFS_BOOT(boot_Linux__Sysfs__Driver);
	PERL_SYSFS_BOOT(boot_Linux__Sysfs__Device);
	PERL_SYSFS_BOOT(boot_Linux__Sysfs__Bus);
	PERL_SYSFS_BOOT(boot_Linux__Sysfs__ClassDevice);
	PERL_SYSFS_BOOT(boot_Linux__Sysfs__Class);
	PERL_SYSFS_BOOT(boot_Linux__Sysfs__Module);
	register_constants();
