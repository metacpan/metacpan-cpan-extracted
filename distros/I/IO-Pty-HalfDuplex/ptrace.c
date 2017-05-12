/* C fragments for the 'ptrace' backend.  Should support at least FreeBSD and
 * Linux.  Most of these functions croak on failure and return false if the
 * slave died.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unistd.h>
#include <sys/types.h>
#include <sys/ptrace.h>
#include <sys/syscall.h>
#include <errno.h>
#include <string.h>
#include <sys/wait.h>


#ifdef __FreeBSD__
#include <machine/reg.h>
#endif

#ifdef PTRACE_TRACEME
/* Linuxish kernels use a different set of macros */
#define PT_TRACE_ME PTRACE_TRACEME
#define PT_SYSCALL PTRACE_SYSCALL
#endif

/* Linux also maintains binary compatibility, so we can't assume any
 * recent (2.2+) kernel features just from the macros
 */
#ifdef PTRACE_O_TRACESYSGOOD
static int have_tracesysgood = 1;
#define SYSCALL_SIG (have_tracesysgood ? (SIGTRAP | 0x80) : SIGTRAP)
#else
#define SYSCALL_SIG SIGTRAP
#endif

static int
pt_maybe_die(const char *fun, int ret)
{
    if (ret < 0)
        croak("%s: %s", fun, strerror(errno));

    return ret;
}

static int
pt_wait(int pid, int *status)
{
    pt_maybe_die("waitpid", waitpid(pid, status, 0));

    STATUS_NATIVE_SET(*status);

    return (WIFSTOPPED(*status)) != 0;
}

int
iphd_ptrace_fork_traced(void)
{
    int cpid = pt_maybe_die("fork", fork());
    int status;

    if (cpid == 0) {
        cpid = getpid();

        setpgid(cpid, cpid);

        pt_maybe_die("ptrace(traceme)", ptrace(PT_TRACE_ME, 0, 0, 0));
        
        return 0;
    }

    if (!pt_wait(cpid, &status)) return -1;

#ifdef PTRACE_O_TRACESYSGOOD
    if (ptrace(PTRACE_SETOPTIONS, cpid, 0, PTRACE_O_TRACESYSGOOD) < 0)
        have_tracesysgood = 0;
#endif

    return cpid;
}

static int
pt_continue_sysenter(int pid)
{
    int status;
    int signo = 0;
    
    while (signo != SYSCALL_SIG) {
        pt_maybe_die("ptrace(cont)", ptrace(
#ifdef PT_TO_SCE
                PT_TO_SCE,
#else
                PT_SYSCALL,
#endif
                pid, (void *) 1, signo));

        if (!pt_wait(pid, &status)) return 0;

        signo = WSTOPSIG(status);
    }

    return 1;
}

#ifdef PT_TO_SCE
/* Lucky!  The kernel announces only sys entries, so there is no
 * danger of confusion.
 */
static int
pt_continue_sysexit(int pid)
{
    (void) pid;
    return 1;
}
#else
#define pt_continue_sysexit pt_continue_sysenter
#endif


static int
pt_is_blocky_read(int pid)
{
    int call, arg;
#if defined(__FreeBSD__) && defined(__i386__)
    struct reg rg;
    ptrace(PT_GETREGS, pid, (void*)&rg, 0);
    call = rg.r_eax;
    arg = ptrace(PT_READ_D, pid, (void *) (rg.r_esp + sizeof(int)), 0);
#elif defined(__FreeBSD__) && defined(__amd64__)
    struct reg rg;
    ptrace(PT_GETREGS, pid, (void*)&rg, 0);
    call = rg.r_rax;
    arg = ptrace(PT_READ_D, pid, (void *) (rg.r_rsp + sizeof(register_t)), 0);
#else
#error Unsupported OS/Architecture
#endif
    if (arg)
        return 0;
    return (call == SYS_read || call == SYS_readv);
}

int
iphd_ptrace_continue_to_next_read(int pid)
{
    while(1) {
        if (!pt_continue_sysenter(pid)) return 0;

        if (pt_is_blocky_read(pid)) return 1;

        if (!pt_continue_sysexit(pid)) return 0;
    }
}
