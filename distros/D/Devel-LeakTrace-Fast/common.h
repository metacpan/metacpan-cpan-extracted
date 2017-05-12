/* common.h */

#ifndef __COMMON_H
#define __COMMON_H

#define PADSIZE \
    (sizeof(void *)-1)

#define PAD(s) \
    (((s) + PADSIZE) & ~PADSIZE)

/* MAX() clashes with Perl */
#define NMAX(a, b) \
    ((a) > (b) ? (a) : (b))
#define NMIN(a, b) \
    ((a) < (b) ? (a) : (b))

#define ASSERT(x)    ((void) 0)
#define REPORT()     ((void) 0)

enum {
    ERR_None = 0,
    ERR_Not_Enough_Memory = 1,
    ERR_Illegal_Hash_Key = 2,
};

#endif                          /* __COMMON_H */
