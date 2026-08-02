#ifndef FT_CORE_H
#define FT_CORE_H

/* The vendored Fetch C core, assembled as a unity build (included once from
 * Fetch.xs, after the Perl headers). Order matters:
 *   1. ft_backend.h   - the readiness-backend vtable + event types
 *   2. backend_*.c     - the backend implementations (self-guard by platform)
 *   3. ft_future.h     - the native Future (needs the loop hook below)
 *   4. ft_loop.h       - the minimal event loop (defines that hook)
 */

#include "ft_win.h"        /* socket/IO portability shim (Winsock on Windows) */
#include "ft_backend.h"

#include "backend_kqueue.c"
#include "backend_epoll.c"
#include "backend_poll.c"      /* also defines hm_backend_create() on POSIX */
#include "backend_select.c"    /* Windows backend + hm_backend_create() there */
#include "backend_iouring.c"

#include "ft_future.h"
#include "ft_loop.h"
#include "ft_http.h"      /* HTTP/1.1 client state machine */

#include "ft_headers.h"   /* Fetch::Headers container ops */
#include "ft_cookiejar.h" /* Fetch::CookieJar store */
#include "ft_json.h"      /* JSON encode/decode via Cpanel::JSON::XS / JSON::PP */

#endif /* FT_CORE_H */
