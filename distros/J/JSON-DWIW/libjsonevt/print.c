/* Creation date: 2008-12-03T12:59:04Z
 * Authors: Don
 */

#ifdef __GNUC__
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "jsonevt_config.h"
#include "print.h"
#include "jsonevt_utils.h"

#define UNLESS(stuff) if (! stuff)

#define MEM_CPY(dst_buf, src_buf, size) memcpy(dst_buf, src_buf, size)


int
js_vasprintf(char **ret, const char *fmt, va_list *ap_ptr) {
#if !defined(JSONEVT_ON_WINDOWS) && defined(HAVE_VASPRINTF)
    return vasprintf(ret, fmt, *ap_ptr);
#else
    char buf[4096];
    int rv = 0;

    UNLESS (ret) {
        return 0;
    }
    
    *ret = NULL;

    rv = vsnprintf(buf, 4096, fmt, *ap_ptr);
    if (rv < 0) {
        return rv;
    }

    if (rv >= 4096) {
        /* just drop the rest of the msg */
        rv = 4095;
    }

    JSONEVT_NEW(*ret, rv + 1, char);
    UNLESS (*ret) {
        return -1;
    }

    MEM_CPY(*ret, buf, rv + 1);
    
    (*ret)[rv] = '\x00'; /* in case the original buf was not large enough */

    return rv;
#endif
}

int
js_asprintf(char ** ret, const char * fmt, ...) {
    va_list ap;
    int rv = 0;
    
    va_start(ap, fmt);

    rv = js_vasprintf(ret, fmt, &ap);

    va_end(ap);

    return rv;
}

