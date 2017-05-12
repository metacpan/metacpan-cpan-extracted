/*
 * $Id: Ptrace.xs,v 0.1 2015/01/14 10:07:56 dankogai Exp $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <unistd.h>
#include <sys/ptrace.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <machine/reg.h>

MODULE = FreeBSD::amd64::Ptrace		PACKAGE = FreeBSD::amd64::Ptrace

PROTOTYPES: ENABLE

IV
pt_ptrace(request, pid, addr, data)
    IV request;
    IV pid;
    IV addr;
    IV data;
CODE:
    RETVAL = ptrace(request, pid, (caddr_t)addr, data);
OUTPUT:
    RETVAL

IV
xs_getcall(pid)
	IV pid;
CODE:
    struct reg r;
    ptrace(PT_GETREGS, pid, (caddr_t)&r, 0);
    RETVAL = r.r_rax;
OUTPUT:
    RETVAL

IV
xs_setcall(pid, call)
  IV pid; IV call;
CODE:
    struct reg r;
    ptrace(PT_GETREGS, pid, (caddr_t)&r, 0);
    r.r_rax = call;
    RETVAL = ptrace(PT_SETREGS, pid, (caddr_t)&r, 0);
OUTPUT:
    RETVAL

PROTOTYPES: DISABLE

void
xs_getregs(pid)
    IV pid;
CODE:
{
    struct reg r;
    ptrace(PT_GETREGS, pid, (caddr_t)&r, 0);
    EXTEND(SP, 25);
    ST(0) =  newSViv(r.r_r15);
    ST(1) =  newSViv(r.r_r14);
    ST(2) =  newSViv(r.r_r13);
    ST(3) =  newSViv(r.r_r12);
    ST(4) =  newSViv(r.r_r11);
    ST(5) =  newSViv(r.r_r10);
    ST(6) =  newSViv(r.r_r9);
    ST(7) =  newSViv(r.r_r8);
    ST(8) =  newSViv(r.r_rdi);
    ST(9) =  newSViv(r.r_rsi);
    ST(10) = newSViv(r.r_rbp);
    ST(11) = newSViv(r.r_rbx);
    ST(12) = newSViv(r.r_rdx);
    ST(13) = newSViv(r.r_rcx);
    ST(14) = newSViv(r.r_rax);
    ST(15) = newSViv(r.r_trapno);
    ST(16) = newSViv(r.r_fs);
    ST(17) = newSViv(r.r_gs);
    ST(18) = newSViv(r.r_err);
    ST(19) = newSViv(r.r_es);
    ST(20) = newSViv(r.r_ds);
    ST(21) = newSViv(r.r_rip);
    ST(22) = newSViv(r.r_cs);
    ST(23) = newSViv(r.r_rflags);
    ST(24) = newSViv(r.r_rsp);
    ST(25) = newSViv(r.r_ss);
    XSRETURN(26);
}

void
xs_setregs(pid, r_r15, r_r14, r_r13, r_r12, r_r11, r_r10, r_r9, r_r8, r_rdi, r_rsi, r_rbp, r_rbx, r_rdx, r_rcx, r_rax, r_trapno, r_fs, r_gs, r_err, r_es, r_ds, r_rip, r_cs, r_rflags, r_rsp, r_ss)
    IV pid;
    IV r_r15;
    IV r_r14;
    IV r_r13;
    IV r_r12;
    IV r_r11;
    IV r_r10;
    IV r_r9;
    IV r_r8;
    IV r_rdi;
    IV r_rsi;
    IV r_rbp;
    IV r_rbx;
    IV r_rdx;
    IV r_rcx;
    IV r_rax;
    IV r_trapno;
    IV r_fs;
    IV r_gs;
    IV r_err;
    IV r_es;
    IV r_ds;
    IV r_rip;
    IV r_cs;
    IV r_rflags;
    IV r_rsp;
    IV r_ss;
CODE:
{
    struct reg r;
    r.r_r15    = r_r15;
    r.r_r14    = r_r14;
    r.r_r13    = r_r13;
    r.r_r12    = r_r12;
    r.r_r11    = r_r11;
    r.r_r10    = r_r10;
    r.r_r9     = r_r9;
    r.r_r8     = r_r8;
    r.r_rdi    = r_rdi;
    r.r_rsi    = r_rsi;
    r.r_rbp    = r_rbp;
    r.r_rbx    = r_rbx;
    r.r_rdx    = r_rdx;
    r.r_rcx    = r_rcx;
    r.r_rax    = r_rax;
    r.r_trapno = r_trapno;
    r.r_fs     = r_fs;
    r.r_gs     = r_gs;
    r.r_err    = r_err;
    r.r_es     = r_es;
    r.r_ds     = r_ds;
    r.r_rip    = r_rip;
    r.r_cs     = r_cs;
    r.r_rflags = r_rflags;
    r.r_rsp    = r_rsp;
    r.r_ss     = r_ss;
    ST(0) = newSViv(ptrace(PT_SETREGS, pid, (caddr_t)&r, 0));
    XSRETURN(1);
}
