#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <linux/unistd.h>
#include <sched.h>

/*
 * This declaration isn't used and looks useless. But for some
 * reason I don't understand at all, for some versions of perl
 * with some build configurations running on some systems,
 * this declaration is the difference between XS code that works
 * (specifically, passing t/11-exercise-all.t) and code that
 * segfaults. For the same reason, the  cpu_set_t  variables
 * in  xs_sched_getaffinity_get_affinity()  below are declared
 * static . 
 *
 * Any insights into this issue would be profoundly appreciated.
 */
char ___linux_sched_getaffinity_dummy[4096];

void diag()
{
  fprintf(stderr,"---\n");
  fprintf(stderr,"diag CPU_SETSIZE=%d\n", CPU_SETSIZE);
  fprintf(stderr,"diag sizeof(__cpu_mask)=%d\n", (int) sizeof(__cpu_mask));
  fprintf(stderr,"diag __NCPUBITS=%d\n", (int) __NCPUBITS);
  fprintf(stderr,"diag sizeof(cpu_set_t)=%d\n", (int) sizeof(cpu_set_t));
  fprintf(stderr,"diag sizeof(pid_t)=%d\n", (int) sizeof(pid_t));
}


MODULE = Sys::CpuAffinity        PACKAGE = Sys::CpuAffinity


int
xs_sched_getaffinity_get_affinity(pid,maskarray,debug_flag)
	int pid
        AV *maskarray
	int debug_flag
  CODE:
    int i, z;
    int r = 0;
    int ncpus = __NCPUBITS;
    static cpu_set_t _set2, *_set1;

    if(debug_flag) diag();
    if(debug_flag) fprintf(stderr,"getaffinity0\n");
    _set1 = &_set2;
    if(debug_flag) {
      fprintf(stderr,"getaffinity1 pid=%d size=%d %d ncpu=%d cpuset=%p\n",
              (int) pid, (int) CPU_SETSIZE, (int) sizeof(cpu_set_t),
              ncpus, (void *) _set1);
    }
    /* RT 94560: CPU_SETSIZE might be less than sizeof(cpu_set_t) ? */
    z = sched_getaffinity((pid_t) pid, sizeof(cpu_set_t), _set1);
#ifdef CPU_COUNT
    ncpus = CPU_COUNT(_set1);
#endif
    if(debug_flag) fprintf(stderr,"getaffinity2 ncpus=%d\n", ncpus);
    if (z) {
      if(debug_flag) fprintf(stderr,"getaffinity3 z=%d err=%d\n", z, errno);
      r = 0;
    } else {
      av_clear(maskarray);
      if(debug_flag) fprintf(stderr,"getaffinity5\n");
      /* tests.reproducible-builds.org/debian/rb-pkg/unstable/i386/
         libsys-cpuaffinity-perl.html:
             __NCPUBITS=32 but taskset,/proc/cpuinfo say there are 34 cpus */
      for (i = 0, r = 0; i < ncpus; i++) {
        if(debug_flag) fprintf(stderr,"getaffinity6 i=%d r=%d\n", i, r);
        if (CPU_ISSET(i, &_set2)) {
          r |= 1;
          av_push(maskarray, newSViv(i));
          if(debug_flag) fprintf(stderr,"getaffinity8 add %d to mask\n", i);
        }
      }
      if(debug_flag) fprintf(stderr,"getaffinitya r=%d\n",r);
    }
    RETVAL = r;
  OUTPUT:
    RETVAL
