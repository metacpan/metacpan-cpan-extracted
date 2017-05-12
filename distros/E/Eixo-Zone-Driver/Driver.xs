#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <errno.h>
#include <sched.h>

#include <sys/errno.h>
#include <sys/mman.h>

#include <sys/capability.h>

#define CLONE_ALL 0

#define InputStream	PerlIO *


static int
clone_cb (void *arg)
{
  dSP;

  PUSHMARK (SP);

  PUTBACK;

  int count = call_sv (sv_2mortal ((SV *)arg), G_SCALAR);

  SPAGAIN;

  int return_value = count ? SvIV (POPs) : 0;

  PUTBACK;

  return return_value;
}

MODULE = Eixo::Zone::Driver	PACKAGE = Eixo::Zone::Driver

PROTOTYPES: ENABLE

SV * mi_setns(fichero, tipo_ns)

	InputStream	fichero
	int	tipo_ns
PPCODE:
		
	int fd = -1;
	
	ST(0) = sv_newmortal();
	
	fd = PerlIO_fileno(fichero);
	
	if(setns(fd, tipo_ns) == 0)
		XPUSHs(sv_2mortal(newSVnv(0)));
	else
		XPUSHs(sv_2mortal(newSVnv(errno)));
		

int mi_getpid()

	CODE:
	RETVAL = 0;
	RETVAL = (long)getpid();

	OUTPUT:
	RETVAL	


SV * mi_unshare(flags)

	int flags
PPCODE:

	ST(0) = sv_newmortal();

	if(unshare(flags) == 0)
		XPUSHs(sv_2mortal(newSVnv(0)));
	else
		XPUSHs(sv_2mortal(newSVnv(errno)));

	
int mi_clone (SV *sub, IV stacksize, int flags, SV *ptid = 0, SV *tls = &PL_sv_undef)
	CODE:
{
  	if (!stacksize)
          stacksize = 4 << 20;

        pid_t ptid_;
        char *stack_ptr = mmap (0, stacksize, PROT_EXEC | PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_GROWSDOWN | MAP_STACK, -1, 0);

	#ifndef __hppa
	  stack_ptr += stacksize - 16;
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

#include <sys/vfs.h>
void mi_caps()
	PPCODE:

		cap_t caps;

		caps = cap_get_proc();
	
		char * caps_string = cap_to_text(caps, NULL);

		XPUSHs(sv_2mortal(newSVpv(caps_string, strlen(caps_string))));
	
