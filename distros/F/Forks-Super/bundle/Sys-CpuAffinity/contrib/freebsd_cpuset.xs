#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <sys/param.h>
#include <sys/cpuset.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <sched.h>
#include <stdio.h>

int num_cpus_sysctl()
{
  int mib[2], ncpu;
  size_t len;

  mib[0] = CTL_HW;
  mib[1] = HW_NCPU;
  len = sizeof(ncpu);
  sysctl(mib, 2, &ncpu, &len, NULL, 0);
  return ncpu;
}

int getaffinity_freebsd(int pid, AV *mask, int debug)
{
  cpulevel_t level = CPU_LEVEL_WHICH;
  cpuwhich_t which = CPU_WHICH_PID;
  id_t id = (id_t) pid;
  size_t setsize;
  cpuset_t cpumask;
  int i, r;

  setsize = sizeof(cpumask);
  if (debug) {
    fprintf(stderr,"calling cpuset_getaffinity(%d,%d,%d,%d,&cpumask)\n",
            (int) level, (int) which, (int) id, (int) setsize);
  }
  r = cpuset_getaffinity(level, which, id, setsize, &cpumask);
  if (debug) {
    fprintf(stderr,"cpuset_getaffinity return value: %d\n", r);
  }
  if (r != 0) {
    if (errno == EINVAL) {
      fprintf(stderr, "cpuset_getaffinity: invalid level or which arg\n");
    } else if (errno == EDEADLK) {
      fprintf(stderr, "cpuset_getaffinity: EDEADLK encountered\n");
    } else if (errno == EFAULT) {
      fprintf(stderr, "cpuset_getaffinity: EFAULT - invalid cpu mask\n");
    } else if (errno == ESRCH) {
      fprintf(stderr, "cpuset_getaffinity: ESRCH - invalid pid\n");
    } else if (errno == ERANGE) {
      fprintf(stderr, "cpuset_getaffinity: ERANGE - invalid cpusetsize\n");
    } else if (errno == EPERM) {
      fprintf(stderr, "cpuset_getaffinity: EPERM - "
                      "no permission to get affinity for pid=%d\n", pid);
    } else {
      fprintf(stderr, "cpuset_getaffinity: unknown error %d\n", errno);
    }
    return 0;
  } else {
    int ncpu = num_cpus_sysctl();
    int nset = 0;
    if (debug) {
      fprintf(stderr,"num_cpus_sysctl() returned: %d\n", ncpu);
    }
    if (ncpu <= 0) {
      fprintf(stderr, "getaffinity_freebsd: "
                      "failed to get num cpus from sysctl\n");
      ncpu = 32;
    }
    for (i = 0; i < ncpu; i++) {
      if (CPU_ISSET(i, &cpumask)) {
        nset++;
        av_push(mask, newSViv(i));
        if (debug) {
          fprintf(stderr,"cpu #%d is set\n", i);
        }
      } else if (debug) {
        fprintf(stderr,"cpu #%d is clear\n", i);
      }
    }
    if (nset == 0) {
      fprintf(stderr, "getaffinity_freebsd: no cpu set in cpumask\n");
      for (i = 0; i < ncpu; i++) {
        av_push(mask, newSViv(i));
      }
    }
    return 1;
  }
}

int setaffinity_freebsd(int pid, AV *mask)
{
  cpulevel_t level = CPU_LEVEL_WHICH;
  cpuwhich_t which = CPU_WHICH_PID;
  id_t id = (id_t) pid;
  size_t setsize;
  cpuset_t cpumask;
  int i, r;

  int n = av_len(mask) + 1;
  int ncpu = num_cpus_sysctl();
  CPU_ZERO(&cpumask);
  if (ncpu > 0 && n > ncpu) {
    fprintf(stderr, "setaffinity_freebsd: "
                    "mask is larger than the number of cpus!\n");
  }
  setsize = sizeof(cpumask);
  for (i = 0; i < n; i++) {
    int proc_id = SvIV(*av_fetch(mask, i, 0));
    if (ncpu <= 0 || proc_id < ncpu) {
      CPU_SET(proc_id, &cpumask);
    } else {
      fprintf(stderr, "setaffinity_freebsd: ignoring request to set "
                      "processor %d which exceeds known num cpus %d\n",
                      proc_id, ncpu);
    }
  }
  r = cpuset_setaffinity(level, which, id, setsize, &cpumask);
  if (r != 0) {
    if (errno == EINVAL) {
      fprintf(stderr, "cpuset_setaffinity: EINVAL - "
                      "bad level, which, or mask arg\n");
    } else if (errno == EDEADLK) {
      fprintf(stderr, "cpuset_setaffinity: EDEADLK found\n");
    } else if (errno == EFAULT) {
      fprintf(stderr, "cpuset_setaffinity: EFAULT - invalid mask pointer\n");
    } else if (errno == ESRCH) {
      fprintf(stderr, "cpuset_setaffinity: ESRCH - invalid pid\n");
    } else if (errno == ERANGE) {
      fprintf(stderr, "cpuset_setaffinity: ERANGE - bad cpusetsize\n");
    } else if (errno == EPERM) {
      fprintf(stderr, "cpuset_setaffinity: EPERM - "
                      "no permission to set affinity on pid=%d\n", pid);
    } else {
      fprintf(stderr, "cpuset_setaffinity: unexpected error no=%d\n", errno);
    }
    return 0;
  } else {
    return 1;
  }
}

MODULE = Sys::CpuAffinity     PACKAGE = Sys::CpuAffinity

int
xs_getaffinity_freebsd(pid,mask,debug)
    int pid
    AV *mask
    int debug
  CODE:
    RETVAL = getaffinity_freebsd(pid,mask,debug);
  OUTPUT:
    RETVAL

int 
xs_setaffinity_freebsd(pid,mask)
    int pid
    AV *mask
  CODE:
    RETVAL = setaffinity_freebsd(pid,mask);
  OUTPUT:
    RETVAL

int
xs_num_cpus_freebsd()
  CODE:
    RETVAL = num_cpus_sysctl();
  OUTPUT:
    RETVAL
