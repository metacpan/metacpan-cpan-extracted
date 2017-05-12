#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "securebits.h"

#include <errno.h>
#include <sys/capability.h>
#include <sys/prctl.h>
#include <stdio.h>
#include <unistd.h>

#define CAP_EFFECTIVE 0
#define CAP_PERMITTED 1
#define CAP_INHERITABLE 2
#include "const-c.inc"

#ifdef PR_SET_PTRACER
#define NOT_SET (-1)
static int __cached_ptracer;
#endif

MODULE = Linux::Prctl     PACKAGE = Linux::Prctl

INCLUDE: const-xs.inc

int
get_dumpable()
    CODE:
        RETVAL = prctl(PR_GET_DUMPABLE, 0, 0, 0, 0);
    OUTPUT:
        RETVAL

int
set_dumpable(dumpable)
    int dumpable
    CODE:
        RETVAL = prctl(PR_SET_DUMPABLE, dumpable, 0, 0, 0);
    OUTPUT:
        RETVAL

int
get_endian()
    CODE:
        int endianness;
        if(prctl(PR_GET_ENDIAN, &endianness, 0, 0, 0))
            XSRETURN_UNDEF;
        RETVAL = endianness;
    OUTPUT:
        RETVAL

int
set_endian(endianness)
    INIT:
        int endianness = 0;
    CODE:
        RETVAL = prctl(PR_SET_ENDIAN, endianness, 0, 0, 0);
    OUTPUT:
        RETVAL

int get_fpemu()
    INIT:
        int fpemu = 0;
    CODE:
        if(prctl(PR_GET_FPEMU, &fpemu, 0, 0, 0))
            XSRETURN_UNDEF;
        RETVAL = fpemu;
    OUTPUT:
        RETVAL

int
set_fpemu(fpemu)
    int fpemu
    CODE:
        RETVAL = prctl(PR_SET_FPEMU, fpemu, 0, 0, 0);
    OUTPUT:
        RETVAL

int get_fpexc()
    INIT:
        int fpexc = 0;
    CODE:
        if(prctl(PR_GET_FPEXC, &fpexc, 0, 0, 0))
            XSRETURN_UNDEF;
        RETVAL = fpexc;
    OUTPUT:
        RETVAL

int
set_fpexc(fpexc)
    int fpexc
    CODE:
        RETVAL = prctl(PR_SET_FPEXC, fpexc, 0, 0, 0);
    OUTPUT:
        RETVAL

=for comment

New in 2.6.32, but named and implemented inconsistently. The linux
implementation has two ways of setting the policy to the default, and thus
needs an extra argument. We ignore the first argument and always all
PR_MCE_KILL_SET. This makes our implementation simpler and keeps the prctl
interface more consistent

=cut

#ifdef PR_MCE_KILL
#define PR_GET_MCE_KILL PR_MCE_KILL_GET
#define PR_SET_MCE_KILL PR_MCE_KILL
int
set_mce_kill(mce_kill)
    int mce_kill
    CODE:
        RETVAL = prctl(PR_SET_MCE_KILL, PR_MCE_KILL_SET, mce_kill, 0, 0);
    OUTPUT:
        RETVAL

int
get_mce_kill()
    CODE:
        RETVAL = prctl(PR_GET_MCE_KILL, 0, 0, 0, 0);
    OUTPUT:
        RETVAL

#endif

char *
get_name()
    INIT:
        char *name = (char*)malloc(32);
    CODE:
        prctl(PR_GET_NAME, name, 0, 0, 0);
        RETVAL = name;
    OUTPUT:
        RETVAL

int
set_name(name)
    char *name
    CODE:
        RETVAL = prctl(PR_SET_NAME, name, 0, 0, 0);
    OUTPUT:
        RETVAL

int
get_pdeathsig()
    INIT:
        int signal;
    CODE:
        prctl(PR_GET_PDEATHSIG, &signal, 0, 0, 0);
        RETVAL = signal;
    OUTPUT:
        RETVAL

int
set_pdeathsig(signal)
    int signal
    CODE:
        RETVAL = prctl(PR_SET_PDEATHSIG, signal, 0, 0, 0);
    OUTPUT:
        RETVAL

#ifdef PR_SET_PTRACER
int
set_ptracer(pid)
    int pid
    CODE:
        RETVAL = prctl(PR_SET_PTRACER, pid, 0, 0, 0);
        __cached_ptracer = pid;
    OUTPUT:
        RETVAL

int get_ptracer()
    CODE:
        if(__cached_ptracer == NOT_SET){
            __cached_ptracer = (int)getppid();
        }
        RETVAL = __cached_ptracer;
    OUTPUT:
        RETVAL

#endif

#ifdef PR_SET_SECCOMP
int
set_seccomp(val)
    int val
    CODE:
        RETVAL = prctl(PR_SET_SECCOMP, val, 0, 0, 0);
    OUTPUT:
        RETVAL

int
get_seccomp()
    CODE:
        RETVAL = prctl(PR_GET_SECCOMP, 0, 0, 0, 0);
    OUTPUT:
        RETVAL

#endif

#ifdef PR_SET_SECUREBITS
int
set_securebits(bits)
    int bits
    CODE:
        RETVAL = prctl(PR_SET_SECUREBITS, bits, 0, 0, 0);
    OUTPUT:
        RETVAL

int
get_securebits()
    CODE:
        RETVAL = prctl(PR_GET_SECUREBITS, 0, 0, 0, 0);
    OUTPUT:
        RETVAL

#endif

#ifdef PR_GET_TIMERSLACK
int
set_timerslack(timerslack)
    int timerslack
    CODE:
        RETVAL = prctl(PR_SET_TIMERSLACK, timerslack, 0, 0, 0);
    OUTPUT:
        RETVAL

int
get_timerslack()
    CODE:
        RETVAL = prctl(PR_GET_TIMERSLACK, 0, 0, 0, 0);
    OUTPUT:
        RETVAL

#endif

int
set_timing(timing)
    int timing
    CODE:
        RETVAL = prctl(PR_SET_TIMING, timing, 0, 0, 0);
    OUTPUT:
        RETVAL

int
get_timing()
    CODE:
        RETVAL = prctl(PR_GET_TIMING, 0, 0, 0, 0);
    OUTPUT:
        RETVAL

#ifdef PR_SET_TSC
int
set_tsc(tsc)
    int tsc
    CODE:
        RETVAL = prctl(PR_SET_TSC, tsc, 0, 0, 0);
    OUTPUT:
        RETVAL

int
get_tsc()
    CODE:
        int tsc;
        prctl(PR_GET_TSC, &tsc, 0, 0, 0);
        RETVAL = tsc;
    OUTPUT:
        RETVAL

#endif

int
set_unalign(unalign)
    int unalign
    CODE:
        RETVAL = prctl(PR_SET_UNALIGN, unalign, 0, 0, 0);
    OUTPUT:
        RETVAL

int
get_unalign()
    CODE:
        int unalign;
        prctl(PR_GET_UNALIGN, &unalign, 0, 0, 0);
        RETVAL = unalign;
    OUTPUT:
        RETVAL

#ifdef PR_CAPBSET_DROP
int
capbset_drop(cap)
    int cap
    CODE:
        RETVAL = prctl(PR_CAPBSET_DROP, cap, 0, 0, 0);
    OUTPUT:
        RETVAL

int
capbset_read(cap)
    int cap
    CODE:
        RETVAL = prctl(PR_CAPBSET_READ, cap, 0, 0, 0);
    OUTPUT:
        RETVAL

#endif

int
get_cap(flag, cap)
    int flag
    int cap
    CODE:
        cap_flag_value_t isset;
        cap_t caps = cap_get_proc();
        if(cap_get_flag(caps, (cap_value_t)cap, (cap_flag_t)flag, &isset) == -1)
            croak("cap_get_flag failed: %s", strerror(errno));
        cap_free(caps);
        RETVAL = isset;
    OUTPUT:
        RETVAL

int
set_cap(flag, cap, val)
    int flag
    int cap
    int val
    CODE:
        cap_flag_value_t isset;
        cap_t caps = cap_get_proc();
        if(cap_set_flag(caps, (cap_flag_t)flag, 1, (const cap_value_t *)&cap, (cap_flag_value_t)val) == -1)
            croak("cap_set_flag failed: %s", strerror(errno));
        cap_set_proc(caps);
        cap_free(caps);
        RETVAL = isset;
    OUTPUT:
        RETVAL
