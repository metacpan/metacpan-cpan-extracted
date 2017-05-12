#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>


#include <sys/types.h>
#include <sys/sysmp.h>
#include <stdio.h>

MODULE = Sys::CpuAffinity       PACKAGE = Sys::CpuAffinity

int
xs_irix_sysmp_setaffinity(pid,cpu)
	int pid
	int cpu
    CODE:
	/*
	 * IRIX allows us to instruct a process to run on a single specific CPU,
	 * or to allow it to run on any CPU.
	 *
	 * The  cpu  argument should be a value between  0  and  numCpus-1  to
	 * choose a single processor to run it on, or -1 to run 
	 * on all processors.
	 *
	 * New and untested code as of v1.00
	 */
	int error;
	int result = 0;
	if (cpu == -1) {
	    error = sysmp(MP_RUNANYWHERE_PID, pid);
	    if (error) {
		fprintf(stderr, "sysmp(MP_RUNANYWHERE_PID,%d) error: %d\n", pid, error);
		result = 0;
	    } else {
		result = 1;
	    }
	} else {
	    error = sysmp(MP_MUSTRUN_PID, pid, cpu);
	    if (error) {
		fprintf(stderr, "sysmp(MP_MUSTRUN_PID,%d,%d) error: %d\n", pid, cpu, error);
		result = 0;
	    } else {
		result = 1;
	    }
	}
	RETVAL = result;
    OUTPUT:
	RETVAL


int
xs_irix_sysmp_getaffinity(pid)
	int pid
    CODE:
	int result = 0;
	result = sysmp(MP_GETMUSTRUN_PID, pid);
	if (result == -1) {
	    if (errno != EINVAL) {
		fprintf(stderr, "sysmp(MP_GETMUSTRUN_PID,%d) error: %d %s\n",
			        errno, strerror(errno));
		result = -2;
	    } else {
		/* process can run on any processor. */
	    }
	}
	RETVAL = result;
    OUTPUT:
	RETVAL


