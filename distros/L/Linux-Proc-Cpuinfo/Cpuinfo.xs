#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <proccpuinfo.h>

typedef proccpuinfo* Linux__Proc__Cpuinfo;

MODULE = Linux::Proc::Cpuinfo   PACKAGE = Linux::Proc::Cpuinfo		

Linux::Proc::Cpuinfo
new(package, ...)
        char *package
    PREINIT:
        char *filename = NULL;
    PPCODE:
        if (items > 1) {
            filename = (char *)SvPV_nolen(ST(1));
            proccpuinfo_set_filename(filename);
        }

        proccpuinfo *info = proccpuinfo_read();
        if (!info) {
            return XSRETURN_UNDEF;
        }

        /*
         * libproccpuinfo does not return NULL for files that do not exist.
         * Check if we have read access to the file. Else return undef.
         */
        if (filename && access(filename, R_OK) == -1) {
            return XSRETURN_UNDEF;
        }

        ST(0) = newSV(0);
        sv_setref_pv(ST(0), "Linux::Proc::Cpuinfo", (void *)info);
        XSRETURN(1);

void
destroy(self)
        Linux::Proc::Cpuinfo self
    CODE:
        proccpuinfo_free(self);

SV *
architecture(self)
        Linux::Proc::Cpuinfo self
    CODE:
        RETVAL = newSVpv(self->architecture, 0);
    OUTPUT:
        RETVAL

SV *
hardware_platform(self)
        Linux::Proc::Cpuinfo self
    CODE:
        RETVAL = newSVpv(self->hardware_platform, 0);
    OUTPUT:
        RETVAL

SV *
frequency(self)
        Linux::Proc::Cpuinfo self
    CODE:
        if (self->frequency == 0) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVnv(self->frequency);
        }
    OUTPUT:
        RETVAL

SV *
bogomips(self)
        Linux::Proc::Cpuinfo self
    CODE:
        if (self->bogomips == 0) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVnv(self->bogomips);
        }
    OUTPUT:
        RETVAL

SV *
cache(self)
        Linux::Proc::Cpuinfo self
    CODE:
        if (self->cache == 0) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVuv(self->cache);
        }
    OUTPUT:
        RETVAL

SV *
cpus(self)
        Linux::Proc::Cpuinfo self
    CODE:
        RETVAL = newSVuv(self->cpus);
    OUTPUT:
        RETVAL
