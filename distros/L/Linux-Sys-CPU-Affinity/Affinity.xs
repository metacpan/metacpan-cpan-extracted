// PERL_NO_GET_CONTEXT is not used here, so it's OK to define it after inculding these files
#include "EXTERN.h"
#include "perl.h"

// There are a lot of macro about threads: USE_ITHREADS, USE_5005THREADS, I_PTHREAD, I_MACH_CTHREADS, OLD_PTHREADS_API
// This symbol, if defined, indicates that Perl should be built to use the interpreter-based threading implementation.
#ifndef USE_ITHREADS
#   define PERL_NO_GET_CONTEXT
#endif

#include "XSUB.h"

#ifdef I_PTHREAD
#   include "pthread.h"
#endif

#ifdef I_MACH_CTHREADS
#   include "mach/cthreads.h"
#endif


#include <sched.h>
#include <errno.h>
#include <sys/sysinfo.h>
//#include <unistd.h>

struct xs_state {
    int max_cpus;
    cpu_set_t *set;
    size_t size;
    char *class_name;
};

typedef struct xs_state Linux_Sys_CPU_Affinity;

static inline int get_available_nprocs (void) {

    static int available_cpus_cnt = 0;

    /* get available amount of CPU cores */
    if (available_cpus_cnt == 0)
        available_cpus_cnt = get_nprocs(); // sysconf(_SC_NPROCESSORS_ONLN);

    /* if we're failed, then use constant, mostly it equals to 1024 */
    if (available_cpus_cnt == -1)
        available_cpus_cnt = CPU_SETSIZE;

    return available_cpus_cnt;
}

inline void init_set (Linux_Sys_CPU_Affinity *cpuset, AV *av) {

    if (cpuset->set != NULL)
        CPU_FREE(cpuset->set);

    cpuset->size = CPU_ALLOC_SIZE(cpuset->max_cpus);
    cpuset->set = CPU_ALLOC(cpuset->max_cpus);

    if (cpuset->set == NULL) {
        SV *msg = sv_2mortal( newSVpvf("Failed to allocate memory for %i CPUs", cpuset->max_cpus) );
        croak((char *) SvPV_nolen(msg));
    }

    CPU_ZERO_S(cpuset->size, cpuset->set);

    if (av != NULL) {
        SSize_t i;
        SSize_t av_len = av_len(av) + 1;
        for (i = 0; i < av_len; i++) {
            size_t cpu = SvIV((SV*)*av_fetch(av, i, 0)); // SvIVX to coerce value into IV
            //Perl_warner_nocontext(aTHX_ packWARN(WARN_QW), "value = %i\n", cpu);
            CPU_SET_S(cpu, cpuset->size, cpuset->set);
        }
    }
}

inline AV* _extract_and_validate_av(SV *sv) {

    if (!SvOK(sv))
        croak("the CPU's list can't be undefined");

    if (SvTIED_mg(sv, PERL_MAGIC_tied))
        croak("tied objects aren't supported");

    if (!SvROK(sv))
        croak("the CPU's list must be an array reference");

    SV *ref = SvRV(sv);
    AV *av;

    switch (SvTYPE(ref)) {
        case SVt_PVAV: // $ref eq "ARRAY"
            av = (AV *) ref;
            break;
        default:       // $ref ne "ARRAY"
            croak("the CPU's list must be an array reference");
    }

    SSize_t i;
    SSize_t bad_arg = -1;
    // SV **arr = AvARRAY(av);

    for (i = av_len(av); i >= 0; i--) {
        SV *val = (SV *) *av_fetch(av, i, 0);
        // SV *val = arr[i];
        if (!SvOK(val) || !SvIOK(val)) {
            bad_arg = i;
            break;
        }
    }

    if (bad_arg != -1) {
        croak("Not an integer at position %i", bad_arg);
    }

    return av;
}

inline Linux_Sys_CPU_Affinity* make_from_object(Linux_Sys_CPU_Affinity *cpuset, int copy_set) {

    Linux_Sys_CPU_Affinity *new_cpuset = (Linux_Sys_CPU_Affinity *) safemalloc(sizeof(Linux_Sys_CPU_Affinity));
    uint32_t cpu;

    new_cpuset->max_cpus = cpuset->max_cpus;
    new_cpuset->class_name = cpuset->class_name;

    init_set(new_cpuset, NULL);

    if (copy_set != 0)
        for (cpu = 0; cpu < new_cpuset->max_cpus; cpu++) {
            int res = CPU_ISSET_S(cpu, cpuset->size, cpuset->set);
            if (res != 0)
                CPU_SET_S(cpu, new_cpuset->size, new_cpuset->set);
        }

    return new_cpuset;
}

inline AV* get_cpus_from_cpuset(Linux_Sys_CPU_Affinity *cpuset) {
    AV* av = newAV();    
    uint32_t cpu;
    for (cpu = 0; cpu < cpuset->max_cpus; cpu++) {
        int res = CPU_ISSET_S(cpu, cpuset->size, cpuset->set);
        if (res != 0)
            av_push(av, newSVuv(cpu));
    }
    sv_2mortal((SV*) av);
    return av;
}

SV* get_sched_error_text(int error_code, int is_get_affinity) {
    SV *error = sv_2mortal(newSV(0));
    switch (error_code) {
        case EFAULT:
            sv_setpv(error, "A supplied memory address was invalid");
            break;
        case EINVAL:
            if (is_get_affinity)
                sv_setpv(error, "The cpusetsize is smaller than the size of the affinity mask used by the kernel");
            else
                sv_setpv(error, "The affinity bit mask mask contains no processors that are currently physically on the system and permitted to the thread");
            break;
        case EPERM:
            sv_setpv(error, "The calling thread does not have appropriate privileges");
            break;
        case ESRCH:
            sv_setpv(error, "The thread whose ID is pid could not be found");
            break;
        default:
            sv_setpv(error, "Unknown error has occurred");
    }
    return error;
}


MODULE = Linux::Sys::CPU::Affinity		PACKAGE = Linux::Sys::CPU::Affinity

PROTOTYPES: DISABLE

Linux_Sys_CPU_Affinity* new(class_name, sv = &PL_sv_undef)
    char *class_name
    SV *sv
PREINIT:
    Linux_Sys_CPU_Affinity *cpuset;
    AV* av = NULL;
CODE:

    if (SvOK(sv))
        av = _extract_and_validate_av(sv);

    cpuset = (Linux_Sys_CPU_Affinity *) safemalloc(sizeof(Linux_Sys_CPU_Affinity));

    cpuset->set = NULL;
    cpuset->max_cpus = get_available_nprocs();
    cpuset->class_name = class_name;

    init_set(cpuset, av);

    // ENTER; SAVETMPS; // {
    // code
    // FREETMPS; LEAVE; // }

    RETVAL = cpuset;
OUTPUT:
    RETVAL


Linux_Sys_CPU_Affinity* clone (cpuset)
    Linux_Sys_CPU_Affinity *cpuset
CODE:
    char* class_name = cpuset->class_name;
    RETVAL = make_from_object(cpuset, 1);
OUTPUT:
    RETVAL


Linux_Sys_CPU_Affinity* cpu_and (cpusetA, cpusetB)
    Linux_Sys_CPU_Affinity *cpusetA
    Linux_Sys_CPU_Affinity *cpusetB
CODE:
    char* class_name = cpusetA->class_name;

    if (cpusetA->size != cpusetB->size)
        croak("The size of given cpusets are different");
    
    Linux_Sys_CPU_Affinity *new_cpuset = make_from_object(cpusetA, 1);

    CPU_AND_S(cpusetA->size, new_cpuset->set, cpusetA->set, cpusetB->set);
    RETVAL = new_cpuset;
OUTPUT:
    RETVAL


Linux_Sys_CPU_Affinity* cpu_or (cpusetA, cpusetB)
    Linux_Sys_CPU_Affinity *cpusetA
    Linux_Sys_CPU_Affinity *cpusetB
CODE:
    char* class_name = cpusetA->class_name;

    if (cpusetA->size != cpusetB->size)
        croak("The size of given cpusets are different");
    
    Linux_Sys_CPU_Affinity *new_cpuset = make_from_object(cpusetA, 1);

    CPU_OR_S(cpusetA->size, new_cpuset->set, cpusetA->set, cpusetB->set);
    RETVAL = new_cpuset;
OUTPUT:
    RETVAL


Linux_Sys_CPU_Affinity* cpu_xor (cpusetA, cpusetB)
    Linux_Sys_CPU_Affinity *cpusetA
    Linux_Sys_CPU_Affinity *cpusetB
CODE:
    char* class_name = cpusetA->class_name;

    if (cpusetA->size != cpusetB->size)
        croak("The size of given cpusets are different");
    
    Linux_Sys_CPU_Affinity *new_cpuset = make_from_object(cpusetA, 1);

    CPU_XOR_S(cpusetA->size, new_cpuset->set, cpusetA->set, cpusetB->set);
    RETVAL = new_cpuset;
OUTPUT:
    RETVAL


void cpu_zero(cpuset)
    Linux_Sys_CPU_Affinity *cpuset
CODE:
    init_set(cpuset, NULL);
    XSRETURN_EMPTY;


void reset(cpuset, sv = &PL_sv_undef)
    Linux_Sys_CPU_Affinity *cpuset
    SV *sv
PREINIT:
    AV* av = NULL;
CODE:
    if (SvOK(sv))
        av = _extract_and_validate_av(sv);
    init_set(cpuset, av);
    XSRETURN_EMPTY;


IV cpu_isset (cpuset, cpu)
    Linux_Sys_CPU_Affinity *cpuset
    UV cpu
PPCODE:
    int res = CPU_ISSET_S((uint32_t) cpu, cpuset->size, cpuset->set);
    mXPUSHu( res );
    XSRETURN(1);


void cpu_set (cpuset, cpu)
    Linux_Sys_CPU_Affinity *cpuset
    UV cpu
PPCODE:
    CPU_SET_S((uint32_t) cpu, cpuset->size, cpuset->set);
    XSRETURN_EMPTY;


void cpu_clr (cpuset, cpu)
    Linux_Sys_CPU_Affinity *cpuset
    UV cpu
PPCODE:
    CPU_CLR_S((uint32_t) cpu, cpuset->size, cpuset->set);
    XSRETURN_EMPTY;


UV cpu_count(cpuset)
    Linux_Sys_CPU_Affinity *cpuset
PPCODE:
    int cpu_count = CPU_COUNT_S(cpuset->size, cpuset->set);
    mXPUSHu( cpu_count ); // PUSHs(sv_2mortal(newSVuv(cpu_count)));
    XSRETURN(1);


IV cpu_equal (cpusetA, cpusetB)
    Linux_Sys_CPU_Affinity *cpusetA
    Linux_Sys_CPU_Affinity *cpusetB
PPCODE:
    int res = 0;
    if (cpusetA->size == cpusetB->size)
        res = CPU_EQUAL_S(cpusetA->size, cpusetA->set, cpusetB->set);
    mXPUSHu( res );
    XSRETURN(1);


AV* get_cpus(cpuset)
    Linux_Sys_CPU_Affinity *cpuset
CODE:
    RETVAL = get_cpus_from_cpuset(cpuset);
OUTPUT:
    RETVAL


AV* get_affinity(cpuset, pid)
    Linux_Sys_CPU_Affinity *cpuset
    UV pid
CODE:
    Linux_Sys_CPU_Affinity *new_cpuset = make_from_object(cpuset, 0);
    int res = sched_getaffinity((pid_t) pid, new_cpuset->size, new_cpuset->set);
    if (res == -1) {
        SV *error = get_sched_error_text(errno, 1);
        croak((char *) SvPV_nolen(error));
    }
    RETVAL = get_cpus_from_cpuset(new_cpuset);
    safefree(new_cpuset);
OUTPUT:
    RETVAL


IV set_affinity(cpuset, pid)
    Linux_Sys_CPU_Affinity *cpuset
    UV pid
PPCODE:
    int res = sched_setaffinity((pid_t) pid, cpuset->size, cpuset->set);
    if (res == -1) {
        SV *error = get_sched_error_text(errno, 0);
        croak((char *) SvPV_nolen(error));
    }
    mXPUSHi( res );
    XSRETURN(1);


void DESTROY (cpuset)
PPCODE:
    Linux_Sys_CPU_Affinity *self = (Linux_Sys_CPU_Affinity *) SvUV(SvRV(ST(0)));
    if (PL_dirty)
        return;
    CPU_FREE(self->set);
    safefree(self);
    XSRETURN_EMPTY;


IV get_nprocs ()
PPCODE:
    int nprocs = get_available_nprocs();
    mXPUSHi( nprocs );
    XSRETURN(1);
