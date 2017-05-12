#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <sys/types.h>
#include <sys/processor.h>
#include <sys/procset.h>
int setaffinity_processor_bind(int pid,int mask)
{
  int r,z;
  idtype_t idtype = P_PID;
  id_t id = (id_t) pid;
  processorid_t processorid = (processorid_t) mask;
  processorid_t obind = (processorid_t) mask;
  r = processor_bind(idtype, id, processorid, &obind);
  if (r != 0) {
    if (errno == EFAULT) {
      fprintf(stderr,"getaffinity_processor_bind: error code EFAULT\n");
      return 0;
    } else if (errno == EINVAL) {
      fprintf(stderr,"getaffinity_processor_bind: error code EINVAL\n");
      return 0;
    } else if (errno == EPERM) {
      fprintf(stderr,"getaffinity_processor_bind: no permission to pbind %d\n",
	      pid);
      return 0;
    } else if (errno == ESRCH) {
      fprintf(stderr,"getaffinity_processor_bind: no such PID %d\n", pid);
      return 0;
    } else {
      fprintf(stderr,"getaffinity_processor_bind: unknown error %d\n", errno);
      return 0;
    }
  }
  return !r;
}
int setaffinity_processor_bind_debug(int pid,int mask)
{
  int r,z;
  idtype_t idtype = P_PID;
  id_t id = (id_t) pid;
  processorid_t processorid = (processorid_t) mask;
  processorid_t obind = (processorid_t) mask;
  fprintf(stderr,"calling processor_bind(%d,%d,%d,&%d)\n",
	  idtype, id, processorid, obind);
  r = processor_bind(idtype, id, processorid, &obind);
  fprintf(stderr,"processor_bind return value: %d\n", r);
  if (r != 0) {
    if (errno == EFAULT) {
      fprintf(stderr,"getaffinity_processor_bind: error code EFAULT\n");
      return 0;
    } else if (errno == EINVAL) {
      fprintf(stderr,"getaffinity_processor_bind: error code EINVAL\n");
      return 0;
    } else if (errno == EPERM) {
      fprintf(stderr,"getaffinity_processor_bind: no permission to pbind %d\n",
	      pid);
      return 0;
    } else if (errno == ESRCH) {
      fprintf(stderr,"getaffinity_processor_bind: no such PID %d\n", pid);
      return 0;
    } else {
      fprintf(stderr,"getaffinity_processor_bind: unknown error %d\n", errno);
      return 0;
    }
  }
  return !r;
}
int setaffinity_processor_unbind(int pid)
{
  return setaffinity_processor_bind(pid, PBIND_NONE);
}

asdfafasdf

MODULE = Sys::CpuAffinity    PACKAGE = Sys::CpuAffinity


int
xs_setaffinity_processor_bind(pid,mask)
        int pid
	int mask
    CODE:
	/* Bind a process to a single CPU. For Solaris. */
	RETVAL = setaffinity_processor_bind(pid,mask);
    OUTPUT:
	RETVAL

int
xs_setaffinity_processor_unbind(pid)
	int pid
    CODE:
	/* Allow a process to run on all CPUs. For Solaris. */
	RETVAL = setaffinity_processor_unbind(pid);
    OUTPUT:
	RETVAL


