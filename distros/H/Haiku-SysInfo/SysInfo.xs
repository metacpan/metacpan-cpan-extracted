#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef bool
#include <OS.h>

MODULE = Haiku::SysInfo PACKAGE = Haiku::SysInfo

PROTOTYPES: DISABLE

void
_sysinfo()
  PREINIT:
    system_info si;
  PPCODE:
    get_system_info(&si);
    EXTEND(SP, 15);
    PUSHs(sv_2mortal(newSViv(si.id[0])));
    PUSHs(sv_2mortal(newSViv(si.id[1])));
    PUSHs(sv_2mortal(newSVnv(si.boot_time)));
    PUSHs(sv_2mortal(newSViv(si.cpu_count)));
    PUSHs(sv_2mortal(newSViv(si.cpu_type)));
    PUSHs(sv_2mortal(newSViv(si.cpu_revision)));
    PUSHs(sv_2mortal(newSVnv(si.cpu_clock_speed)));
    PUSHs(sv_2mortal(newSVnv(si.bus_clock_speed)));
    PUSHs(sv_2mortal(newSViv(si.platform_type)));
    PUSHs(sv_2mortal(newSViv(si.max_pages)));
    PUSHs(sv_2mortal(newSViv(si.used_pages)));
    PUSHs(sv_2mortal(newSVpv(si.kernel_name, 0)));
    PUSHs(sv_2mortal(newSVpv(si.kernel_build_date, 0)));
    PUSHs(sv_2mortal(newSVpv(si.kernel_build_time, 0)));
    PUSHs(sv_2mortal(newSVnv(si.kernel_version)));

SV *
cpu_brand_string(obj, int cpu_num = 0)
  PREINIT:
    cpuid_info info;
    uint32 code;
  CODE:
    /* check cpuid supports our needs */
    if (get_cpuid(&info, 0x80000000, cpu_num) >= B_NO_ERROR
        && info.regs.eax >= 0x80000004) {
	fprintf(stderr, "code supported\n");
       /* CPU brand string should be available */
      RETVAL = newSVpvn("", 0);
      for (code = 0x80000002; code <= 0x80000004; ++code) {
        uint32 tmp;
        get_cpuid(&info, code, cpu_num);
        /* this cpuid request likes a eax,ebx,ecx,edx order, but
	   cpuid_info swaps ecx and edx */
	tmp = info.regs.ecx;
	info.regs.ecx = info.regs.edx;
	info.regs.edx = tmp;
	if (memchr(info.as_chars, '\0', sizeof(info.as_chars))) {
	  sv_catpv(RETVAL, info.as_chars);
	  break;
	}
	else {
	  sv_catpvn(RETVAL, info.as_chars, sizeof(info.as_chars));
	}
      }
    }
    else {
      /* else no info available */
      XSRETURN_EMPTY;
    }
  OUTPUT:
    RETVAL

