#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/errno.h>
#include <sys/mman.h>

#undef _GNU_SOURCE
#define _GNU_SOURCE
#include <sched.h>
#include <unistd.h>
#include <sys/syscall.h>

#ifdef __has_include
  #if !__has_include("linux/kcmp.h") // use "" as GCC wrongly expands macros
    #undef SYS_kcmp
  #endif
#endif

#ifdef SYS_kcmp
  #include "linux/kcmp.h"
  #define kcmp(pid1,pid2,type,idx1,idx2) \
    syscall (SYS_kcmp, (pid_t)pid1, (pid_t)pid2, \
             (int)type, (unsigned long)idx1, (unsigned long)idx2)
#else
  #define kcmp(pid1,pid2,type,idx1,idx2) \
    (errno = ENOSYS, -1)
#endif

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
#   define const_iv(name)       { # name, (IV)name },
#   define const_iv_clone(name) { # name, (IV) CLONE_ ## name },
#   ifdef CLONE_FILES
      const_iv_clone (FILES)
#   endif
#   ifdef CLONE_FS
      const_iv_clone (FS)
#   endif
#   ifdef CLONE_NEWNS
      const_iv_clone (NEWNS)
#   endif
#   ifdef CLONE_VM
      const_iv_clone (VM)
#   endif
#   ifdef CLONE_THREAD
      const_iv_clone (THREAD)
#   endif
#   ifdef CLONE_SIGHAND
      const_iv_clone (SIGHAND)
#   endif
#   ifdef CLONE_SYSVSEM
      const_iv_clone (SYSVSEM)
#   endif
#   ifdef CLONE_NEWUTS
      const_iv_clone (NEWUTS)
#   endif
#   ifdef CLONE_NEWIPC
      const_iv_clone (NEWIPC)
#   endif
#   ifdef CLONE_NEWNET
      const_iv_clone (NEWNET)
#   endif
#   ifdef CLONE_PTRACE
      const_iv_clone (PTRACE)
#   endif
#   ifdef CLONE_VFORK
      const_iv_clone (VFORK)
#   endif
#   ifdef CLONE_SETTLS
      const_iv_clone (SETTLS)
#   endif
#   ifdef CLONE_PARENT_SETTID
      const_iv_clone (PARENT_SETTID)
#   endif
#   ifdef CLONE_CHILD_CLEARTID
      const_iv_clone (CHILD_CLEARTID)
#   endif
#   ifdef CLONE_DETACHED
      const_iv_clone (DETACHED)
#   endif
#   ifdef CLONE_UNTRACED
      const_iv_clone (UNTRACED)
#   endif
#   ifdef CLONE_CHILD_SETTID
      const_iv_clone (CHILD_SETTID)
#   endif
#   ifdef CLONE_NEWUSER
      const_iv_clone (NEWUSER)
#   endif
#   ifdef CLONE_NEWPID
      const_iv_clone (NEWPID)
#   endif
#   ifdef CLONE_IO
      const_iv_clone (IO)
#   endif
#   ifdef CLONE_NEWCGROUP
      const_iv_clone (NEWCGROUP)
#   endif
#   ifdef SYS_kcmp
      const_iv (KCMP_FILE)
      const_iv (KCMP_VM)
      const_iv (KCMP_FILES)
      const_iv (KCMP_FS)
      const_iv (KCMP_SIGHAND)
      const_iv (KCMP_IO)
      const_iv (KCMP_SYSVSEM)
      const_iv (KCMP_FILE)
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

int
pivot_root (SV *new_root, SV *old_root)
	CODE:
        RETVAL = syscall (SYS_pivot_root,
                          (const char *)SvPVbyte_nolen (new_root),
                          (const char *)SvPVbyte_nolen (old_root));
	OUTPUT:
        RETVAL

int
kcmp (IV pid1, IV pid2, IV type, UV idx1 = 0, UV idx2 = 0)

