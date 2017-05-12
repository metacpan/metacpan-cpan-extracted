#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <sys/param.h>
#include <sys/cpuset.h>
#include <sched.h>
#include <stdio.h>

MODULE = Sys::CpuAffinity     PACKAGE = Sys::CpuAffinity

int 
xs_getaffinity_cpuset_get_affinity(pid)
    int pid
  CODE:
    /* Get the affinity of a processes. Available for FreeBSD >= 7.1 */
    cpulevel_t level = CPU_LEVEL_WHICH;
    cpuwhich_t which = CPU_WHICH_PID;
    id_t id = (id_t) pid;
    size_t setsize;
    cpuset_t cpumask;
    int i, r, z;

    setsize = sizeof(cpumask);
    r = cpuset_getaffinity(level, which, id, setsize, &cpumask);
    if (r != 0) {
      if (errno == EINVAL) {
	fprintf(stderr, "cpuset_getaffinity: invalid level/which\n");
      } else if (errno == EDEADLK) {
	fprintf(stderr, "cpuset_getaffinity: EDEADLK encountered\n");
      } else if (errno == EFAULT) {
	fprintf(stderr, "cpuset_getaffinity: EFAULT - invalid cpu mask\n");
      } else if (errno == ESRCH) {
	fprintf(stderr, "cpuset_getaffinity: ESRCH - invalid pid\n");
      } else if (errno == ERANGE) {
	fprintf(stderr, "cpuset_getaffinity: ERANGE - invalid cpusetsize\n");
      } else if (errno == EPERM) {
	fprintf(stderr, "cpuset_getaffinity: EPERM - no permission to get affinity for %d\n", pid);
      } else {
	fprintf(stderr, "cpuset_getaffinity: unknown error %d\n", errno);
      }
      RETVAL = 0;
    } else {
      z = 0;
      for (i = 0; i < 32; i++) {
        if (CPU_ISSET(i, &cpumask)) {
	  z |= (1 << i);
        }
      }
      RETVAL = z;
    }
  OUTPUT:
    RETVAL

