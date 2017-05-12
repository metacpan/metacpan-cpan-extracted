/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/**
 * @file
 * @brief a simple hash function for jspell
 */

#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"

/* The following hash algorithm is due to Ian Dall, with slight
 * modifications by Geoff Kuenning to reflect the results of testing
 * with the English dictionaries actually distributed with ispell.
 */


/** ...  */
#define HASHSHIFT   5

#ifdef NO_CAPITALIZATION_SUPPORT
/** Capitalize a character */
#define HASHUPPER(c)        c
#else /* NO_CAPITALIZATION_SUPPORT */
/** Capitalize a character */
#define HASHUPPER(c)        mytoupper(c)
#endif /* NO_CAPITALIZATION_SUPPORT */

/**
 * @brief hash function
 *
 * @param s string to hash
 * @param hashtblsize size of the hash table
 */
int hash(register ichar_t *s, register int hashtblsize)
{
    register long h = 0;
    register int  i;

#ifdef ICHAR_IS_CHAR
    for (i = 4;  i--  &&  *s != 0;  )
        h = (h << 8) | HASHUPPER (*s++);
#else /* ICHAR_IS_CHAR */
    for (i = 2;  i--  &&  *s != 0;  )
        h = (h << 16) | HASHUPPER (*s++);
#endif /* ICHAR_IS_CHAR */

    while (*s != 0) {
        /* We have to do circular shifts the hard way, since C doesn't
           have them even though the hardware probably does.  Oh,
           well. */
        h = (h << HASHSHIFT)
            | ((h >> (32 - HASHSHIFT)) & ((1 << HASHSHIFT) - 1));
        h ^= HASHUPPER (*s++);
    }
    return (unsigned long) h % hashtblsize;
}
