/*
 * Hyperman.xs - Root XS file
 *
 * Thin wrapper (Chandra-style layout): pulls in the C core from
 * include/hyperman/ - the backend vtable + implementations (unity build),
 * the Future primitive, and the loop/server core - then the per-package
 * XS fragments via INCLUDE:. All Hyperman-namespace behavior lives in C;
 * the .pm files are documentation/loader stubs.
 */

#ifndef _GNU_SOURCE
#define _GNU_SOURCE            /* memmem on glibc */
#endif
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "hm_compat.h"    /* perl API shims (XS_INTERNAL, mg_findext, croak_sv) */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <signal.h>
#include <sys/wait.h>
#ifdef __linux__
#include <sched.h>
#endif

#include "hyperman.h"

/* readiness backends: one translation unit, guarded per platform */
#include "backend_kqueue.c"
#include "backend_epoll.c"
#include "backend_iouring.c"
#include "backend_poll.c"

#include "hm_future.h"
#include "hm_ratelimit.h"   /* fork-shared denylist + rate counters (arena) */
#include "hm_core.h"
#include "hm_abi_impl.h"

MODULE = Hyperman		PACKAGE = Hyperman

PROTOTYPES: DISABLE

INCLUDE: xs/hyperman.xs
INCLUDE: xs/future.xs
INCLUDE: xs/loop.xs
INCLUDE: xs/writer.xs
INCLUDE: xs/event.xs
INCLUDE: xs/abi.xs
