#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <sys/param.h>
#include <sys/cpuset.h>
#include <sched.h>
int setaffinity_cpuset_setaffinity(int pid, int mask)
{
    cpulevel_t level = CPU_LEVEL_WHICH;
    cpuwhich_t which = CPU_WHICH_PID;
    id_t id = (id_t) pid;
    size_t setsize;
    cpuset_t cpumask;
    int i, r;

    setsize = sizeof(cpumask);
    CPU_ZERO(&cpumask);
    for (i=0; i<32; i++) {
	if (mask & (1 << i)) {
	    CPU_SET(i, &cpumask);
	}
    }

    r = cpuset_setaffinity(level, which, id, setsize, &cpumask);
    if (r != 0) {
      if (errno == EINVAL) {
	fprintf(stderr, "cpuset_getaffinity: invalid level/which\n");
	return 0;
      } else if (errno == EDEADLK) {
	fprintf(stderr, "cpuset_getaffinity: EDEADLK encountered\n");
	return 0;
      } else if (errno == EFAULT) {
	fprintf(stderr, "cpuset_getaffinity: EFAULT - invalid cpu mask\n");
	return 0;
      } else if (errno == ESRCH) {
	fprintf(stderr, "cpuset_getaffinity: ESRCH - invalid pid\n");
	return 0;
      } else if (errno == ERANGE) {
	fprintf(stderr, "cpuset_getaffinity: ERANGE - invalid cpusetsize\n");
	return 0;
      } else if (errno == EPERM) {
	fprintf(stderr, "cpuset_getaffinity: EPERM - no permission to get affinity for %d\n", pid);
	return 0;
      } else {
	fprintf(stderr, "cpuset_getaffinity: unknown error %d\n", errno);
	return 0;
      }
    }
    return !r;
}

MODULE = Sys::CpuAffinity     PACKAGE = Sys::CpuAffinity

int
xs_cpuset_set_affinity(pid,mask)
	int pid
	int mask
    CODE:
	/* Sets the cpu affinity of a process. Available for FreeBSD >= 7.1 */
	RETVAL = setaffinity_cpuset_setaffinity(pid,mask);
    OUTPUT:
	RETVAL


