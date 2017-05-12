#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/errno.h>
#include <sys/mman.h>

#undef _GNU_SOURCE
#define _GNU_SOURCE
#include <sched.h>

/* from schmorp.h */
static int
s_fileno (SV *fh, int wr)
{
  dTHX;
  SvGETMAGIC (fh);

  if (SvROK (fh))
    {
      fh = SvRV (fh);
      SvGETMAGIC (fh);
    }

  if (SvTYPE (fh) == SVt_PVGV)
    return PerlIO_fileno (wr ? IoOFP (sv_2io (fh)) : IoIFP (sv_2io (fh)));

  if (SvOK (fh) && (SvIV (fh) >= 0) && (SvIV (fh) < 0x7fffffffL))
    return SvIV (fh);

  return -1;
}

static int
clone_cb (void *arg)
{
  dSP;

  PUSHMARK (SP);

  PUTBACK;
  int count = call_sv (sv_2mortal ((SV *)arg), G_SCALAR);
  SPAGAIN;
  int retval = count ? SvIV (POPs) : 0;
  PUTBACK;

  return retval;
}

MODULE = Linux::Clone		PACKAGE = Linux::Clone

PROTOTYPES: ENABLE

BOOT:
  HV *stash = gv_stashpv ("Linux::Clone", 1);

  static const struct {
    const char *name;
    IV iv;
  } *civ, const_iv[] = {
#   define const_iv(name) { # name, (IV) CLONE_ ## name },
#   ifdef CLONE_FILES
      const_iv (FILES)
#   endif
#   ifdef CLONE_FS
      const_iv (FS)
#   endif
#   ifdef CLONE_NEWNS
      const_iv (NEWNS)
#   endif
#   ifdef CLONE_VM
      const_iv (VM)
#   endif
#   ifdef CLONE_THREAD
      const_iv (THREAD)
#   endif
#   ifdef CLONE_SIGHAND
      const_iv (SIGHAND)
#   endif
#   ifdef CLONE_SYSVSEM
      const_iv (SYSVSEM)
#   endif
#   ifdef CLONE_NEWUTS
      const_iv (NEWUTS)
#   endif
#   ifdef CLONE_NEWIPC
      const_iv (NEWIPC)
#   endif
#   ifdef CLONE_NEWNET
      const_iv (NEWNET)
#   endif
#   ifdef CLONE_PTRACE
      const_iv (PTRACE)
#   endif
#   ifdef CLONE_VFORK
      const_iv (VFORK)
#   endif
#   ifdef CLONE_SETTLS
      const_iv (SETTLS)
#   endif
#   ifdef CLONE_PARENT_SETTID
      const_iv (PARENT_SETTID)
#   endif
#   ifdef CLONE_CHILD_CLEARTID
      const_iv (CHILD_CLEARTID)
#   endif
#   ifdef CLONE_DETACHED
      const_iv (DETACHED)
#   endif
#   ifdef CLONE_UNTRACED
      const_iv (UNTRACED)
#   endif
#   ifdef CLONE_CHILD_SETTID
      const_iv (CHILD_SETTID)
#   endif
#   ifdef CLONE_NEWUSER
      const_iv (NEWUSER)
#   endif
#   ifdef CLONE_NEWPID
      const_iv (NEWPID)
#   endif
#   ifdef CLONE_IO
      const_iv (IO)
#   endif
#   ifdef CLONE_NEWCGROUP
      const_iv (NEWCGROUP)
#   endif
  };

  for (civ = const_iv + sizeof (const_iv) / sizeof (const_iv [0]); civ > const_iv; civ--)
    newCONSTSUB (stash, (char *)civ[-1].name, newSViv (civ[-1].iv));

int
clone (SV *sub, IV stacksize, int flags, SV *ptid = 0, SV *tls = &PL_sv_undef)
	CODE:
{
	if (!stacksize)
          stacksize = 4 << 20;

        pid_t ptid_;
        char *stack_ptr = mmap (0, stacksize, PROT_EXEC | PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_GROWSDOWN | MAP_STACK, -1, 0);

	#ifndef __hppa
	  stack_ptr += stacksize - 16; /* be safe and put the sp at 16 bytes below the end */
	#endif

        RETVAL = -1;
        if (stack_ptr != (void *)-1)
          {
            SV *my_sub = newSVsv (sub);
            
            RETVAL = clone (clone_cb, (void *)stack_ptr, flags, (void *)my_sub, &ptid, SvOK (tls) ? SvPV_nolen (tls) : 0, 0);

            if (ptid) sv_setiv (ptid, (IV)ptid_);

            if ((flags & (CLONE_VM | CLONE_VFORK)) != CLONE_VM)
              {
                int old_errno = errno;
                munmap (stack_ptr, stacksize);
                errno = old_errno;
              }
          }
}
	OUTPUT:
        RETVAL

int
unshare (int flags)

int
setns (SV *fh_or_fd, int nstype = 0)
	C_ARGS: s_fileno (fh_or_fd, 0), nstype
