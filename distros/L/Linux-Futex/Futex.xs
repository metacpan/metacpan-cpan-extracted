#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <linux/futex.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>


void futex_wait(int *uadd, int val) {
    syscall(SYS_futex , uadd, FUTEX_WAIT, val, NULL, NULL, 0);
}

void futex_wake(int *uadd, int num) {
    syscall(SYS_futex , uadd, FUTEX_WAKE, num, NULL, NULL, 0);
}

/* var replaced with new if current value = old. old value always returned */
static int cmpxchg (int *var, int old, int new) {
  int ret;

  asm ( "lock cmpxchg %3, %0\n\t"
        "mov %%eax, %1 \n\t"
	: "+m"(*var), "=g"(ret) : "a"(old), "b"(new) : "memory", "cc");
  return ret;
}

/* exchange the two atomically, return the original value of var */
static int xchg (int *var, int new) {
  int ret;
  asm ( "lock xchg %%eax, %0\n\t"
        "mov %%eax, %1 \n\t"
	: "+m"(*var), "=g"(ret) : "a"(new) : "memory");
  return ret;
}

/* Atomically decrement val by 1
 * return 0 if value becomes zero, else non-zero
 */
static int atomic_dec(int *val) {
    int ret;
    asm("lock decl %0\n\t"
        "lahf \n\t"
        "and $0x4000,%%eax \n\t"
        "ror $14, %%eax \n\t"
        "dec %%eax \n\t"
        : "+m"(*val), "=a"(ret) : : "memory", "cc");
    return ret;
}

static void *sv2addr(SV *sv)
{
  if (SvPOK(sv) && SvCUR(sv) == sizeof(void *))
  {
    return *((void **) SvPVX(sv));
  }

  croak("invalid address value");

  return 0;
}

MODULE = Linux::Futex		PACKAGE = Linux::Futex

PROTOTYPES: DISABLE

void
init (buf)
        void *buf = sv2addr(ST(0));
    CODE:
        *((int *)buf) = 0;

void
lock (buf)
        void *buf = sv2addr(ST(0));
    CODE:
        int c;
        int *pmutex = (int *)buf;
        if ((c = cmpxchg (pmutex, 0, 1)) != 0) {
            if (c != 2)
                c = xchg (pmutex, 2);
            while (c != 0) {
                futex_wait (pmutex, 2);
                c = xchg (pmutex, 2);
            }
        }

void
unlock (buf)
        void *buf = sv2addr(ST(0));
    CODE:
        int *pmutex = (int *)buf;
        if (atomic_dec (pmutex) != 1) {
            *((int *)pmutex) = 0;
            futex_wake (pmutex, 1);
        }

void
addr (buf)
    SV *buf
    INIT:
        if (!SvPOK(buf)) croak("requires a string");
        
    CODE:
        STRLEN len;
        char *mem = SvPV(buf, len);
        if (len < 4) croak("string must be at least four bytes");
        ST(0) = sv_2mortal(newSVpvn((char *) &mem, sizeof(void *)));
        XSRETURN(1);
