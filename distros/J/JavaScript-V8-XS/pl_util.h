#ifndef PL_UTIL_H_
#define PL_UTIL_H_

#define UNUSED_ARG(x) (void) x

/* Get 'now' timestamp (microseconds since 1970) */
double now_us(void);

/* Get how many memory pages are currently in use */
long total_memory_pages(void);

#endif
