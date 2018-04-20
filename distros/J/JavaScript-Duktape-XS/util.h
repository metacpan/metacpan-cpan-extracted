#ifndef UTIL_H_
#define UTIL_H_

#include "duktape.h"

#define UNUSED_ARG(x) (void) x

/* Get 'now' timestamp (microseconds since 1970) */
double now_us(void);

/* Get how many memory pages are currently in use */
long total_memory_pages(void);

/* Check for errors after running JS code in duktape */
int check_duktape_call_for_errors(int rc, duk_context* ctx);

#endif
