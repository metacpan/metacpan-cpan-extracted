#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <sys/types.h>
#include <sys/processor.h>
#include <sys/procset.h>
int getaffinity_processor_bind(int pid)
{
  int r,z;
  idtype_t idtype = P_PID;
  id_t id = (id_t) pid;
  processorid_t processorid = PBIND_QUERY;
  processorid_t obind;
  r = processor_bind(idtype, id, processorid, &obind);
  if (r != 0) {
    if (errno == EFAULT) {
      fprintf(stderr,"getaffinity_processor_bind: error code EFAULT %d\n",r);
      return -1;
    } else if (errno == EINVAL) {
      fprintf(stderr,"getaffinity_processor_bind: error code EINVAL %d\n",r);
      return -2;
    } else if (errno == EPERM) {
      fprintf(stderr,
	      "getaffinity_processor_bind: no permission to pbind %d (%d)\n",
	      pid, r);
      return -3;
    } else if (errno == ESRCH) {
      fprintf(stderr,"getaffinity_processor_bind: no such PID %d (%d)\n", 
	             pid, r);
      return -4;
    } else {
      fprintf(stderr,"getaffinity_processor_bind: unknown error %d %d\n",
                     errno, r);
      return -5;
    }
  }
  /* obind is either the value of a single CPU index, or PBIND_NONE
     to indicate an unbound process */
  if (obind == PBIND_NONE) {
    obind = -10;
  }
  return obind;
}

aqreqwert 

MODULE = Sys::CpuAffinity        PACKAGE = Sys::CpuAffinity


int
xs_getaffinity_processor_bind(pid)
	int pid
    CODE:
	/* Use Solaris processor_bind() library function. */
	RETVAL = getaffinity_processor_bind(pid);
    OUTPUT:
	RETVAL



