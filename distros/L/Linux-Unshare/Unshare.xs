#ifndef __linux
#error "No linux. Compile aborted."
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <sched.h>
#ifndef CLONE_NEWNS
# define CLONE_NEWNS		0x00020000	/* Set to create new namespace.  */
#endif
#ifndef CLONE_NEWCGROUP
# define CLONE_NEWCGROUP	0x02000000	/* New cgroup namespace.  */
#endif
#ifndef CLONE_NEWUTS
# define CLONE_NEWUTS		0x04000000	/* New utsname group.  */
#endif
#ifndef CLONE_NEWIPC
# define CLONE_NEWIPC		0x08000000	/* New ipcs.  */
#endif
#ifndef CLONE_NEWUSER
# define CLONE_NEWUSER		0x10000000	/* New user namespace.  */
#endif
#ifndef CLONE_NEWPID
# define CLONE_NEWPID		0x20000000	/* New pid namespace.  */
#endif
#ifndef CLONE_NEWNET
# define CLONE_NEWNET		0x40000000	/* New network namespace.  */
#endif
#define CLONE_CONTAINER CLONE_NEWNS|CLONE_NEWUTS|CLONE_NEWIPC|CLONE_NEWNET|CLONE_NEWPID|CLONE_NEWUSER
#include "const-c.inc"

MODULE = Linux::Unshare		PACKAGE = Linux::Unshare

INCLUDE: const-xs.inc
PROTOTYPES: ENABLE

SV * unshare(int flags)
	CODE:
		ST(0) = sv_newmortal();
		if(unshare(flags) == 0)
			sv_setiv(ST(0), 1);
