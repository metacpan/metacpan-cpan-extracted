/*
 * $Id: Ptrace.xs,v 0.3 2015/01/14 06:22:13 dankogai Exp $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <unistd.h>
#include <sys/ptrace.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <machine/reg.h>

MODULE = FreeBSD::i386::Ptrace		PACKAGE = FreeBSD::i386::Ptrace

PROTOTYPES: ENABLE

int
pt_ptrace(request, pid, addr, data)
    int request;
    int pid;
    int addr;
    int data;
CODE:
    RETVAL = ptrace(request, pid, (caddr_t)addr, data);
OUTPUT:
    RETVAL

int
xs_getcall(pid)
	int pid;
CODE:
    struct reg r;
    ptrace(PT_GETREGS, pid, (caddr_t)&r, 0);
    RETVAL = r.r_eax;
OUTPUT:
    RETVAL

int
xs_setcall(pid, call)
  int pid; int call;
CODE:
    struct reg r;
    ptrace(PT_GETREGS, pid, (caddr_t)&r, 0);
    r.r_eax = call;
    RETVAL = ptrace(PT_SETREGS, pid, (caddr_t)&r, 0);
OUTPUT:
    RETVAL

PROTOTYPES: DISABLE

void
xs_getregs(pid)
    int pid;
CODE:
{
    struct reg r;
    ptrace(PT_GETREGS, pid, (caddr_t)&r, 0);
    EXTEND(SP, 18);
    ST(0) =  newSViv(r.r_fs);
    ST(1) =  newSViv(r.r_es);
    ST(2) =  newSViv(r.r_ds);
    ST(3) =  newSViv(r.r_edi);
    ST(4) =  newSViv(r.r_esi);
    ST(5) =  newSViv(r.r_ebp);
    ST(6) =  newSViv(r.r_isp);
    ST(7) =  newSViv(r.r_ebx);
    ST(8) =  newSViv(r.r_edx);
    ST(9) =  newSViv(r.r_ecx);
    ST(10) = newSViv(r.r_eax);
    ST(11) = newSViv(r.r_trapno);
    ST(12) = newSViv(r.r_err);
    ST(13) = newSViv(r.r_eip);
    ST(14) = newSViv(r.r_cs);
    ST(15) = newSViv(r.r_eflags);
    ST(16) = newSViv(r.r_esp);
    ST(17) = newSViv(r.r_ss);
    ST(18) = newSViv(r.r_gs);
    XSRETURN(19);
}

void
xs_setregs(pid, r_fs, r_es, r_ds, r_edi, r_esi, r_ebp, r_isp, r_ebx, r_edx, r_ecx, r_eax, r_trapno, r_err, r_eip, r_cs, r_eflags, r_esp, r_ss, r_gs)
    int pid;
    int r_fs; int r_es; int r_ds; int r_edi; int r_esi; int r_ebp; int r_isp;
    int r_ebx; int r_edx; int r_ecx; int r_eax; int r_trapno;
    int r_err; int r_eip; int r_cs;  int r_eflags; int r_esp;
    int r_ss; int r_gs;
CODE:
{
    struct reg r;
    r.r_fs =      r_fs;
    r.r_es =      r_es;
    r.r_ds =      r_ds;
    r.r_edi =     r_edi;
    r.r_esi =     r_esi;
    r.r_ebp =     r_ebp;
    r.r_isp =     r_isp;
    r.r_ebx =     r_ebx;
    r.r_edx =     r_edx;
    r.r_ecx =     r_ecx;
    r.r_eax =     r_eax;
    r.r_trapno =  r_trapno;
    r.r_err =     r_err;
    r.r_eip =     r_eip;
    r.r_cs =      r_cs;
    r.r_eflags =  r_eflags;
    r.r_esp =     r_esp;
    r.r_ss =      r_ss;
    r.r_gs =      r_gs;
    ST(0) = newSViv(ptrace(PT_SETREGS, pid, (caddr_t)&r, 0));
    XSRETURN(1);
}
