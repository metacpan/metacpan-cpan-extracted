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

/* The platform headers come from the shim, first and only - the same rule
 * hm_core.h follows. On POSIX hm_win.h expands to exactly the <sys/socket.h>
 * / <sys/uio.h> / netinet / <unistd.h> block this file used to spell out
 * by hand; on Windows it expands to Winsock. Spelling them out here is what
 * broke the 0.23 Windows build: <sys/uio.h> does not exist on MinGW, and it
 * was included eighteen lines above the header that knows that. */
#include "hm_win.h"

/* CRT headers, present everywhere: not the shim's business. */
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <signal.h>

/* The prefork supervisor's headers. hm_core.h compiles that whole half
 * under #ifndef _WIN32 (no fork, no waitpid, no POSIX signals there), so
 * its includes carry the same guard. */
#ifndef _WIN32
#include <sys/wait.h>
#ifdef __linux__
#include <sched.h>
#endif
#endif

#include "hyperman.h"

/* readiness backends: one translation unit, guarded per platform */
#include "backend_kqueue.c"
#include "backend_epoll.c"
#include "backend_iouring.c"
#include "backend_wsapoll.c"
#include "backend_poll.c"

#include "hm_future.h"
#include "hm_ratelimit.h"   /* fork-shared denylist + rate counters (arena) */
#include "hm_bus.h"         /* the cross-worker message bus (same arena idea) */
#include "hm_bus_perl.h"    /* ... and its Perl-side cursor and collector    */
#include "hm_compress.h"   /* gzip on the way out (zlib optional) */
#include "hm_workerhook.h" /* the v4 on_worker_start registry; hm_core fires
                            * it, hm_abi_impl registers into it */
#include "hm_workerhook_perl.h" /* ... and the Perl door onto that registry */
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
INCLUDE: xs/bus.xs
