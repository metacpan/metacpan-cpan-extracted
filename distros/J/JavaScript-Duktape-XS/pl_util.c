#include <stdio.h>
#include <sys/time.h>
#include "duk_console.h"
#include "pl_util.h"

#define FILE_MEMORY_STATUS "/proc/self/statm"

double now_us(void)
{
    struct timeval tv;
    double now = 0.0;
    int rc = gettimeofday(&tv, 0);
    if (rc == 0) {
        now = 1000000.0 * tv.tv_sec + tv.tv_usec;
    }
    return now;
}

long total_memory_pages(void)
{
    long pages = 0;

    /*
     * /proc/[pid]/statm
     *        Provides information about memory usage, measured in pages.
     *            size       total program size
     *                       (same as VmSize in /proc/[pid]/status)
     *            resident   resident set size
     *                       (same as VmRSS in /proc/[pid]/status)
     *            share      shared pages (from shared mappings)
     *            text       text (code)
     *            lib        library (unused in Linux 2.6)
     *            data       data + stack
     *            dirty      dirty pages (unused in Linux 2.6)
     */
    FILE* fp = 0;
    do {
        long size, resident, share, text, lib, data, dirty;
        int nread;
        fp = fopen(FILE_MEMORY_STATUS, "r");
        if (!fp) {
            /* silently ignore, some OSs do not have this file */
            break;
        }
        nread = fscanf(fp, "%ld %ld %ld %ld %ld %ld %ld",
                       &size, &resident, &share, &text, &lib, &data, &dirty);
        if (nread != 7) {
            /* silently ignore, avoid noisy errors */
            break;
        }
        pages = size;
    } while (0);
    if (fp) {
        fclose(fp);
        fp = 0;
    }
    return pages;
}

int check_duktape_call_for_errors(int rc, duk_context* ctx)
{
    if (rc == DUK_EXEC_SUCCESS) {
        /* no error */
        return 1;
    }

    if (duk_is_error(ctx, -1)) {
        /*
         * Error and we should have a stack trace.
         * Accessing .stack might cause an error to be thrown, so wrap this
         * access in a duk_safe_call() if it matters.
         */
        duk_get_prop_string(ctx, -1, "stack");
        duk_console_log(DUK_CONSOLE_FLUSH | DUK_CONSOLE_TO_STDERR,
                        "error: %s\n", duk_safe_to_string(ctx, -1));
        duk_pop(ctx);
        return 0;
    }

    /*
     * Error without a stack trace.
     * Non-Error value, coerce safely to string.
     */
    duk_console_log(DUK_CONSOLE_FLUSH | DUK_CONSOLE_TO_STDERR,
                    "error: %s\n", duk_safe_to_string(ctx, -1));
    return 1;
}
