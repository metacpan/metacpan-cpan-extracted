#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#define NEED_newRV_noinc
#include "ppport.h"

#ifdef __cplusplus
} /* extern "C" */
#endif

#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#define _GNU_SOURCE
#include <sched.h>

MODULE = Linux::CPUAffinity    PACKAGE = Linux::CPUAffinity

PROTOTYPES: DISABLE

static void
Linux::CPUAffinity::set(int pid, AV *cpus)
PREINIT:
    cpu_set_t set;
    int i;
    I32 len;
CODE:
    CPU_ZERO(&set);
    len = av_len(cpus);
    for (i = 0; i <= len; i++) {
        CPU_SET(SvIV(*av_fetch(cpus, i, 0)), &set);
    }
    if (sched_setaffinity(pid, sizeof(set), &set) != 0) {
        croak("failed to call sched_setaffinity(2): %s", strerror(errno));
    }

static SV*
Linux::CPUAffinity::get(int pid)
PREINIT:
    cpu_set_t set;
    int nprocs, cpu_count, i;
    AV *ret;
CODE:
    if (sched_getaffinity(pid, sizeof(set), &set) != 0) {
        croak("failed to call sched_getaffinity(2): %s", strerror(errno));
    }
    nprocs = sysconf(_SC_NPROCESSORS_ONLN);
    cpu_count = CPU_COUNT(&set);
    ret = newAV();
    av_extend(ret, cpu_count);
    for (i = 0; i < nprocs; i++) {
        if (CPU_ISSET(i, &set)) {
            av_push(ret, newSViv(i));
        }
    }
    RETVAL = newRV_noinc((SV *) ret);
OUTPUT:
    RETVAL

static long
Linux::CPUAffinity::num_processors()
CODE:
    RETVAL = sysconf(_SC_NPROCESSORS_ONLN);
OUTPUT:
    RETVAL
